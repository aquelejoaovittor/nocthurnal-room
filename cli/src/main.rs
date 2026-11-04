// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
use std::fs;
use std::path::PathBuf;
use std::process::ExitCode;
use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use nocthurnal_room_core::format::NroomPreset;
use nocthurnal_room_core::interop;

#[derive(Parser)]
#[command(name = "nroom", version, about = "Nocthurnal Room — CLI")]
struct Cli { #[command(subcommand)] cmd: Cmd }

#[derive(Subcommand)]
enum Cmd {
    New { name: String, #[arg(short, long)] out: Option<PathBuf> },
    Validate { path: PathBuf },
    Info { path: PathBuf },
    ImportXmp { xmp_path: PathBuf, #[arg(short, long)] out: Option<PathBuf> },
    ExportXmp { nroom_path: PathBuf, #[arg(short, long)] out: Option<PathBuf> },
}

fn main() -> ExitCode { match run() { Ok(()) => ExitCode::SUCCESS, Err(e) => { eprintln!("erro: {e:#}"); ExitCode::FAILURE } } }

fn run() -> Result<()> {
    let cli = Cli::parse();
    match cli.cmd {
        Cmd::New { name, out } => cmd_new(name, out),
        Cmd::Validate { path } => cmd_validate(path),
        Cmd::Info { path } => cmd_info(path),
        Cmd::ImportXmp { xmp_path, out } => cmd_import_xmp(xmp_path, out),
        Cmd::ExportXmp { nroom_path, out } => cmd_export_xmp(nroom_path, out),
    }
}

fn cmd_new(name: String, out: Option<PathBuf>) -> Result<()> {
    let p = NroomPreset::new(&name);
    let path = out.unwrap_or_else(|| PathBuf::from(format!("{}.nroom", slug(&name))));
    p.write(&path)?;
    println!("criado: {} (id {})", path.display(), p.id);
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

fn cmd_import_xmp(xmp_path: PathBuf, out: Option<PathBuf>) -> Result<()> {
    let xml = fs::read_to_string(&xmp_path).context("Falha ao ler XMP")?;
    let preset = interop::import_xmp(&xml).map_err(|e| anyhow::anyhow!(e))?;
    let path = out.unwrap_or_else(|| xmp_path.with_extension("nroom"));
    preset.write(&path)?;
    println!("Importado com sucesso: {} -> {}", xmp_path.display(), path.display());
    Ok(())
}

fn cmd_export_xmp(nroom_path: PathBuf, out: Option<PathBuf>) -> Result<()> {
    let preset = NroomPreset::read(&nroom_path)?;
    let xml = interop::export_xmp(&preset);
    let path = out.unwrap_or_else(|| nroom_path.with_extension("xmp"));
    fs::write(&path, xml).context("Falha ao escrever XMP")?;
    println!("Exportado com sucesso: {} -> {}", nroom_path.display(), path.display());
    Ok(())
}

fn slug(s: &str) -> String { s.chars().map(|c| if c.is_alphanumeric() { c.to_ascii_lowercase() } else { '-' }).collect::<String>().trim_matches('-').to_string() }
