// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
//! Modelo canônico de parâmetros de edição.
//!
//! Semântica: cada campo é `Option<T>` — `None` significa
//! "este preset não define este parâmetro", o que é diferente de
//! "define como o padrão". Presets são deltas sobre a imagem original.
//!
//! As faixas documentadas aqui DEVEM estar alinhadas com
//! `schemas/nroom-v1.json` e com `format::nroom::validate()`.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct EditParameters {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub basic:        Option<Basic>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tone_curve:   Option<ToneCurve>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub color:        Option<Color>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub split_toning: Option<SplitToning>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub effects:      Option<Effects>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub detail:       Option<Detail>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Basic {
    /// -5.0 .. +5.0 EV
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub exposure:   Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub contrast:   Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub highlights: Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub shadows:    Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub whites:     Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub blacks:     Option<i32>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ToneCurve {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub parametric:  Option<ParametricCurve>,
    /// Pontos (x, y) em [0, 1]^2 — até 512.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub point_curve: Option<Vec<[f64; 2]>>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ParametricCurve {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub shadows:    Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub darks:      Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub lights:     Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub highlights: Option<f64>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Color {
    /// 2000 .. 50000 K
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub temperature: Option<i32>,
    /// -150 .. +150
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tint:        Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub vibrance:    Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub saturation:  Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub hsl:         Option<Hsl>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Hsl {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub hue:        Option<HslChannels>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub saturation: Option<HslChannels>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub luminance:  Option<HslChannels>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct HslChannels {
    #[serde(default, skip_serializing_if = "Option::is_none")] pub red:     Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub orange:  Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub yellow:  Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub green:   Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub aqua:    Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub blue:    Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub purple:  Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub magenta: Option<i32>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct SplitToning {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub shadows:    Option<ToneTint>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub highlights: Option<ToneTint>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub balance:    Option<i32>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ToneTint {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub hue:        Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub saturation: Option<i32>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Effects {
    #[serde(default, skip_serializing_if = "Option::is_none")] pub clarity:           Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub dehaze:            Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub vignette_amount:   Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub vignette_midpoint: Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub vignette_feather:  Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub grain_amount:      Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub grain_size:        Option<i32>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Detail {
    #[serde(default, skip_serializing_if = "Option::is_none")] pub sharpening_amount: Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub sharpening_radius: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub sharpening_detail: Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub luminance_noise:   Option<i32>,
    #[serde(default, skip_serializing_if = "Option::is_none")] pub color_noise:       Option<i32>,
}
