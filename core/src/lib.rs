// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
//! Nocthurnal Room core library.
//!
//! Contém o modelo de domínio (`domain`) e o formato nativo `.nroom`
//! (`format`). Este crate não depende de UI nem de I/O de imagem —
//! essas camadas chegam nas Fases 3 e 5.

pub mod domain;
pub mod format;

pub const APP_NAME:    &str = "Nocthurnal Room";
pub const TEAM_NAME:   &str = "Orbyte Studio";
pub const AUTHOR_LINE: &str = "Orbyte Studio © João Souza & Henrique Santos";
pub const LICENSE_ID:  &str = "AGPL-3.0-or-later";
