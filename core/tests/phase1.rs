// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
//! Testes de aceitação da Fase 1.

use std::fs;
use std::path::{Path, PathBuf};

use nocthurnal_room_core::domain::{Basic, EditParameters};
use nocthurnal_room_core::format::{NroomError, NroomPreset};

fn workspace() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).parent().unwrap().to_path_buf()
}

fn fixtures() -> PathBuf { workspace().join("fixtures") }

#[test]
fn roundtrip_new_save_load_compare() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("p.nroom");

    let mut preset = NroomPreset::new("Round Trip");
    preset.parameters.basic = Some(Basic {
        exposure: Some(0.5), contrast: Some(15), ..Default::default()
    });

    preset.write(&path).unwrap();
    let reloaded = NroomPreset::read(&path).unwrap();
    assert_eq!(preset, reloaded);
}

#[test]
fn roundtrip_preserves_all_groups() {
    let mut preset = NroomPreset::new("Full");
    preset.parameters = EditParameters {
        basic: Some(Basic {
            exposure: Some(0.1), contrast: Some(3), highlights: Some(-10),
            shadows: Some(12), whites: Some(4), blacks: Some(-2),
        }),
        ..Default::default()
    };
    let json = preset.to_json().unwrap();
    let back = NroomPreset::parse(&json).unwrap();
    assert_eq!(preset, back);
}

#[test]
fn rejects_unknown_top_level_field() {
    let bad = r#"{
        "format": "nroom", "format_version": "1.0.0",
        "id": "11111111-1111-4111-8111-111111111111",
        "name": "x", "parameters": {}, "surprise": 1
    }"#;
    assert!(matches!(NroomPreset::parse(bad), Err(NroomError::Json(_))));
}

#[test]
fn rejects_unknown_nested_field() {
    let data = fs::read_to_string(fixtures().join("invalid/unknown-field.nroom")).unwrap();
    assert!(NroomPreset::parse(&data).is_err());
}

#[test]
fn rejects_out_of_range_exposure() {
    let data = fs::read_to_string(fixtures().join("invalid/out-of-range.nroom")).unwrap();
    assert!(NroomPreset::parse(&data).is_err());
}

#[test]
fn rejects_wrong_format_magic() {
    let bad = r#"{
        "format": "lrtemplate", "format_version": "1.0.0",
        "id": "11111111-1111-4111-8111-111111111111",
        "name": "x", "parameters": {}
    }"#;
    assert!(matches!(NroomPreset::parse(bad), Err(NroomError::WrongFormat { .. })));
}

#[test]
fn rejects_malformed_json_without_panic() {
    let bad = "{ this is not json }";
    assert!(matches!(NroomPreset::parse(bad), Err(NroomError::Json(_))));
}

#[test]
fn rejects_empty_name() {
    let bad = r#"{
        "format": "nroom", "format_version": "1.0.0",
        "id": "11111111-1111-4111-8111-111111111111",
        "name": "   ", "parameters": {}
    }"#;
    assert!(matches!(NroomPreset::parse(bad), Err(NroomError::EmptyField("name"))));
}

#[test]
fn fixtures_conform_to_schema() {
    let schema_raw = fs::read_to_string(workspace().join("schemas/nroom-v1.json")).unwrap();
    let schema_json: serde_json::Value = serde_json::from_str(&schema_raw).unwrap();
    let compiled = jsonschema::JSONSchema::options()
        .with_draft(jsonschema::Draft::Draft202012)
        .compile(&schema_json).expect("schema deve compilar");

    for name in ["neutral.nroom", "warm-portrait.nroom"] {
        let raw = fs::read_to_string(fixtures().join("valid").join(name)).unwrap();
        let value: serde_json::Value = serde_json::from_str(&raw).unwrap();
        assert!(compiled.validate(&value).is_ok(), "fixture {name} deveria ser válida");
    }
}

#[test]
fn generated_preset_conforms_to_schema() {
    let schema_raw = fs::read_to_string(workspace().join("schemas/nroom-v1.json")).unwrap();
    let schema_json: serde_json::Value = serde_json::from_str(&schema_raw).unwrap();
    let compiled = jsonschema::JSONSchema::options()
        .with_draft(jsonschema::Draft::Draft202012)
        .compile(&schema_json).unwrap();

    let p = NroomPreset::new("Generated");
    let v = serde_json::to_value(&p).unwrap();
    assert!(compiled.validate(&v).is_ok());
}

#[test]
fn format_version_is_1_x() {
    assert!(nocthurnal_room_core::format::FORMAT_VERSION.starts_with("1."));
    assert_eq!(nocthurnal_room_core::format::FORMAT_MAGIC, "nroom");
}
