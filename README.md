# Nocthurnal Room

Editor fotografico gratuito e open source, focado em presets
interoperaveis e fluxo de trabalho sem assinatura.

Desenvolvido por Orbyte Studio - Joao Souza & Henrique Santos.

## Licenca

- Codigo: GNU AGPL-3.0-or-later (veja LICENSE e NOTICE).
- Marca: veja TRADEMARK.md.

## Status

Fase 1 - fundacao e nucleo de presets.

## O que ja funciona

- Formato nativo .nroom v1.0.0 (JSON Schema 2020-12).
- Modelo de dominio EditParameters em Rust.
- CLI nroom com new, validate, info.
- Round-trip create -> save -> load com testes.

## Como compilar

    cargo build
    cargo test
    cargo run -p nroom -- new "Meu preset" --out preset.nroom
    cargo run -p nroom -- validate preset.nroom

## Estrutura

- schemas/  - JSON Schema do formato .nroom.
- core/     - biblioteca Rust (dominio + formato + validacao).
- cli/      - binario nroom.
- fixtures/ - presets de exemplo.

## Roadmap

- Fase 1 - fundacao, formato, validador, CLI (atual).
- Fase 2 - importacao/exportacao XMP (Lightroom Classic).
- Fase 3 - UI Flutter.
- Fase 4 - biblioteca local.
- Fase 5 - pipeline de imagem.
