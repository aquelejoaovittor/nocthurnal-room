// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
//! Formato nativo `.nroom` — leitura, escrita e validação estrita.
//!
//! Contrato público: `schemas/nroom-v1.json`. Este módulo valida
//! estruturalmente via `serde(deny_unknown_fields)` e semanticamente
//! via `validate()` (faixas de valores). Os dois DEVEM permanecer
//! sincronizados com o schema — os testes garantem isso.

use std::fs;
use std::path::Path;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

use crate::domain::EditParameters;

pub const FORMAT_MAGIC:   &str = "nroom";
pub const FORMAT_VERSION: &str = "1.0.0";

#[derive(Debug, Error)]
pub enum NroomError {
    #[error("falha de I/O: {0}")]
    Io(#[from] std::io::Error),

    #[error("JSON inválido: {0}")]
    Json(#[from] serde_json::Error),

    #[error("formato inesperado: esperado 'nroom', encontrado '{found}'")]
    WrongFormat { found: String },

    #[error("versão incompatível: {found} (esperado 1.x.y)")]
    WrongVersion { found: String },

    #[error("valor fora de faixa: {field} = {value} (min = {min}, max = {max})")]
    OutOfRange { field: String, value: f64, min: f64, max: f64 },

    #[error("campo obrigatório vazio: {0}")]
    EmptyField(&'static str),

    #[error("campo longo demais: {field} ({len} > {max} caracteres)")]
    TooLong { field: &'static str, len: usize, max: usize },

    #[error("metadata precisa ser um objeto JSON")]
    InvalidMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct NroomPreset {
    pub format:         String,
    pub format_version: String,
    pub id:             Uuid,
    pub name:           String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub author:         Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description:    Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub category:       Option<String>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags:           Vec<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub created_at:     Option<DateTime<Utc>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub compatibility:  Option<Compatibility>,
    pub parameters:     EditParameters,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub external_refs:  Vec<ExternalRef>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub metadata:       Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct Compatibility {
    #[serde(default, skip_serializing_if = "Option::is_none")] pub min_app_version: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub requires_masks:  Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub requires_lut:    Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(deny_unknown_fields)]
pub struct ExternalRef {
    #[serde(rename = "type")] pub kind:   String,
    pub sha256:               String,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub name: Option<String>,
}

impl NroomPreset {
    /// Cria um preset mínimo válido com parâmetros padrão.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            format:         FORMAT_MAGIC.into(),
            format_version: FORMAT_VERSION.into(),
            id:             Uuid::new_v4(),
            name:           name.into(),
            author:         Some(crate::AUTHOR_LINE.into()),
            description:    None,
            category:       None,
            tags:           Vec::new(),
            created_at:     Some(Utc::now()),
            compatibility:  None,
            parameters:     EditParameters::default(),
            external_refs:  Vec::new(),
            metadata:       None,
        }
    }

    /// Valida semanticamente o preset (faixas, comprimentos, formato).
    /// A estrutura já foi garantida pelo `serde(deny_unknown_fields)`.
    pub fn validate(&self) -> Result<(), NroomError> {
        if self.format != FORMAT_MAGIC {
            return Err(NroomError::WrongFormat { found: self.format.clone() });
        }
        if !self.format_version.starts_with("1.") {
            return Err(NroomError::WrongVersion { found: self.format_version.clone() });
        }
        if self.name.trim().is_empty() {
            return Err(NroomError::EmptyField("name"));
        }
        if self.name.len() > 200 {
            return Err(NroomError::TooLong {
                field: "name", len: self.name.len(), max: 200,
            });
        }
        if let Some(m) = &self.metadata {
            if !m.is_object() {
                return Err(NroomError::InvalidMetadata);
            }
        }

        if let Some(b) = &self.parameters.basic {
            check_f64(b.exposure, "basic.exposure", -5.0, 5.0)?;
            check_i32(b.contrast,   "basic.contrast",   -100, 100)?;
            check_i32(b.highlights, "basic.highlights", -100, 100)?;
            check_i32(b.shadows,    "basic.shadows",    -100, 100)?;
            check_i32(b.whites,     "basic.whites",     -100, 100)?;
            check_i32(b.blacks,     "basic.blacks",     -100, 100)?;
        }
        if let Some(tc) = &self.parameters.tone_curve {
            if let Some(pc) = &tc.parametric {
                check_f64(pc.shadows,    "tone_curve.parametric.shadows",    -1.0, 1.0)?;
                check_f64(pc.darks,      "tone_curve.parametric.darks",      -1.0, 1.0)?;
                check_f64(pc.lights,     "tone_curve.parametric.lights",     -1.0, 1.0)?;
                check_f64(pc.highlights, "tone_curve.parametric.highlights", -1.0, 1.0)?;
            }
            if let Some(pts) = &tc.point_curve {
                if pts.len() > 512 {
                    return Err(NroomError::TooLong {
                        field: "tone_curve.point_curve", len: pts.len(), max: 512,
                    });
                }
                for p in pts {
                    check_f64(Some(p[0]), "tone_curve.point_curve.x", 0.0, 1.0)?;
                    check_f64(Some(p[1]), "tone_curve.point_curve.y", 0.0, 1.0)?;
                }
            }
        }
        if let Some(c) = &self.parameters.color {
            check_i32(c.temperature, "color.temperature", 2000, 50_000)?;
            check_i32(c.tint,        "color.tint",        -150, 150)?;
            check_i32(c.vibrance,    "color.vibrance",    -100, 100)?;
            check_i32(c.saturation,  "color.saturation",  -100, 100)?;
            if let Some(h) = &c.hsl {
                for (name, ch) in [("hue", &h.hue), ("saturation", &h.saturation), ("luminance", &h.luminance)] {
                    if let Some(ch) = ch {
                        for (k, v) in [
                            ("red", ch.red), ("orange", ch.orange), ("yellow", ch.yellow),
                            ("green", ch.green), ("aqua", ch.aqua), ("blue", ch.blue),
                            ("purple", ch.purple), ("magenta", ch.magenta),
                        ] {
                            check_i32(v, &format!("color.hsl.{name}.{k}"), -100, 100)?;
                        }
                    }
                }
            }
        }
        if let Some(st) = &self.parameters.split_toning {
            for (name, tint) in [("shadows", &st.shadows), ("highlights", &st.highlights)] {
                if let Some(t) = tint {
                    check_i32(t.hue,        &format!("split_toning.{name}.hue"), 0, 359)?;
                    check_i32(t.saturation, &format!("split_toning.{name}.saturation"), 0, 100)?;
                }
            }
            check_i32(st.balance, "split_toning.balance", -100, 100)?;
        }
        if let Some(e) = &self.parameters.effects {
            check_i32(e.clarity,           "effects.clarity",           -100, 100)?;
            check_i32(e.dehaze,            "effects.dehaze",            -100, 100)?;
            check_i32(e.vignette_amount,   "effects.vignette_amount",   -100, 100)?;
            check_i32(e.vignette_midpoint, "effects.vignette_midpoint",    0, 100)?;
            check_i32(e.vignette_feather,  "effects.vignette_feather",     0, 100)?;
            check_i32(e.grain_amount,      "effects.grain_amount",         0, 100)?;
            check_i32(e.grain_size,        "effects.grain_size",           0, 100)?;
        }
        if let Some(d) = &self.parameters.detail {
            check_i32(d.sharpening_amount, "detail.sharpening_amount", 0, 150)?;
            check_f64(d.sharpening_radius, "detail.sharpening_radius", 0.5, 3.0)?;
            check_i32(d.sharpening_detail, "detail.sharpening_detail", 0, 100)?;
            check_i32(d.luminance_noise,   "detail.luminance_noise",   0, 100)?;
            check_i32(d.color_noise,       "detail.color_noise",       0, 100)?;
        }
        Ok(())
    }

    /// Lê e valida um arquivo `.nroom`.
    pub fn read(path: impl AsRef<Path>) -> Result<Self, NroomError> {
        let data = fs::read_to_string(path)?;
        Self::parse(&data)
    }

    /// Serializa como JSON indentado e grava no caminho dado.
    pub fn write(&self, path: impl AsRef<Path>) -> Result<(), NroomError> {
        self.validate()?;
        let json = self.to_json()?;
        fs::write(path, json)?;
        Ok(())
    }

    /// Interpreta o JSON, valida e devolve o preset.
    pub fn parse(json: &str) -> Result<Self, NroomError> {
        let preset: Self = serde_json::from_str(json)?;
        preset.validate()?;
        Ok(preset)
    }

    /// Serialização canônica (JSON indentado, 2 espaços).
    pub fn to_json(&self) -> Result<String, NroomError> {
        Ok(serde_json::to_string_pretty(self)?)
    }
}

fn check_i32(v: Option<i32>, field: &str, min: i32, max: i32) -> Result<(), NroomError> {
    if let Some(v) = v {
        if v < min || v > max {
            return Err(NroomError::OutOfRange {
                field: field.into(), value: v as f64, min: min as f64, max: max as f64,
            });
        }
    }
    Ok(())
}

fn check_f64(v: Option<f64>, field: &str, min: f64, max: f64) -> Result<(), NroomError> {
    if let Some(v) = v {
        if v < min || v > max {
            return Err(NroomError::OutOfRange {
                field: field.into(), value: v, min, max,
            });
        }
    }
    Ok(())
}
