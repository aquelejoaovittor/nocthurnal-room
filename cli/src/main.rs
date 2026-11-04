// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
use std::path::PathBuf;
use std::process::ExitCode;
use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use nocthurnal_room_core::format::NroomPreset;

#[derive(Parser)]
#[command(name = "nroom", version, about = "Nocthurnal Room — CLI")]
struct Cli { #[command(subcommand)] cmd: Cmd }

#[derive(Subcommand)]
enum Cmd {
    New { name: String, #[arg(short, long)] out: Option<PathBuf> },
    Validate { path: PathBuf },
    Info { path: PathBuf },
}

fn main() -> ExitCode { match run() { Ok(()) => ExitCode::SUCCESS, Err(e) => { eprintln!("erro: {e:#}"); ExitCode::FAILURE } } }

fn run() -> Result<()> {
    let cli = Cli::parse();
    match cli.cmd {
        Cmd::New { name, out } => cmd_new(name, out),
        Cmd::Validate { path } => cmd_validate(path),
        Cmd::Info { path } => cmd_info(path),
    }
}

fn cmd_new(name: String, out: Option<PathBuf>) -> Result<()> {
    let preset = NroomPreset::new(&name);
    let path = out.unwrap_or_else(|| PathBuf::from(format!("{}.nroom", slug(&name))));
    preset.write(&path)?;
    println!("criado: {} (id {})", path.display(), preset.id);
    Ok(())
}

fn cmd_validate(path: PathBuf) -> Result<()> {
    let p = NroomPreset::read(&path).with_context(|| format!("falha em {}", path.display()))?;
    println!("válido: {} — formato {} v{}", path.display(), p.format, p.format_version);
    Ok(())
}

fn cmd_info(path: PathBuf) -> Result<()> {
    let p = NroomPreset::read(&path)?;
    println!("nome: {}\nid: {}\nformato: {} v{}", p.name, p.id, p.format, p.format_version);
    if let Some(a) = &p.author { println!("autor: {a}"); }
    println!("\n--- JSON ---\n{}", p.to_json()?);
    Ok(())
}

fn slug(s: &str) -> String { s.chars().map(|c| if c.is_alphanumeric() { c.to_ascii_lowercase() } else { '-' }).collect::<String>().trim_matches('-').to_string() }
