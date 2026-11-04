// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2025 Orbyte Studio — João Souza & Henrique Santos
use crate::domain::*;
use crate::format::NroomPreset;
use roxmltree::Document;
use std::str::FromStr;

pub fn import_xmp(xml: &str) -> Result<NroomPreset, String> {
    let doc = Document::parse(xml).map_err(|e| format!("XML inválido: {}", e))?;
    let mut preset = NroomPreset::new("Importado do Lightroom");
    let mut basic = Basic::default();
    let mut color = Color::default();
    let mut effects = Effects::default();
    let mut has_data = false;

    if let Some(desc) = doc.descendants().find(|n| n.has_tag_name(("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "Description"))) {
        // Procura pelos atributos pelo nome local (ignorando o prefixo 'crs:')
        let get_f64 = |name: &str| desc.attributes().find(|a| a.name() == name).and_then(|a| f64::from_str(a.value()).ok());
        let get_i32 = |name: &str| desc.attributes().find(|a| a.name() == name).and_then(|a| i32::from_str(a.value()).ok());

        if let Some(v) = get_f64("Exposure2012")   { basic.exposure = Some(v); has_data = true; }
        if let Some(v) = get_i32("Contrast2012")   { basic.contrast = Some(v); has_data = true; }
        if let Some(v) = get_i32("Highlights2012") { basic.highlights = Some(v); has_data = true; }
        if let Some(v) = get_i32("Shadows2012")    { basic.shadows = Some(v); has_data = true; }
        if let Some(v) = get_i32("Whites2012")     { basic.whites = Some(v); has_data = true; }
        if let Some(v) = get_i32("Blacks2012")     { basic.blacks = Some(v); has_data = true; }

        if let Some(v) = get_i32("Temperature")    { color.temperature = Some(v); has_data = true; }
        if let Some(v) = get_i32("Tint")           { color.tint = Some(v); has_data = true; }
        if let Some(v) = get_i32("Vibrance")       { color.vibrance = Some(v); has_data = true; }
        if let Some(v) = get_i32("Saturation")     { color.saturation = Some(v); has_data = true; }

        if let Some(v) = get_i32("Clarity2012")    { effects.clarity = Some(v); has_data = true; }
        if let Some(v) = get_i32("Dehaze")         { effects.dehaze = Some(v); has_data = true; }
    }

    if !has_data { return Err("Nenhum parâmetro crs:* encontrado no arquivo.".into()); }

    preset.parameters.basic = Some(basic);
    preset.parameters.color = Some(color);
    preset.parameters.effects = Some(effects);

    preset.validate().map_err(|e| format!("Validação falhou: {}", e))?;
    Ok(preset)
}

pub fn export_xmp(preset: &NroomPreset) -> String {
    let mut attrs = String::new();
    let mut add = |k: &str, v: String| attrs.push_str(&format!("        crs:{}=\"{}\"\n", k, v));

    if let Some(b) = &preset.parameters.basic {
        if let Some(v) = b.exposure   { add("Exposure2012", format!("{:.2}", v)); }
        if let Some(v) = b.contrast   { add("Contrast2012", v.to_string()); }
        if let Some(v) = b.highlights { add("Highlights2012", v.to_string()); }
        if let Some(v) = b.shadows    { add("Shadows2012", v.to_string()); }
        if let Some(v) = b.whites     { add("Whites2012", v.to_string()); }
        if let Some(v) = b.blacks     { add("Blacks2012", v.to_string()); }
    }
    if let Some(c) = &preset.parameters.color {
        if let Some(v) = c.temperature { add("Temperature", v.to_string()); }
        if let Some(v) = c.tint        { add("Tint", v.to_string()); }
        if let Some(v) = c.vibrance    { add("Vibrance", v.to_string()); }
        if let Some(v) = c.saturation  { add("Saturation", v.to_string()); }
    }
    if let Some(e) = &preset.parameters.effects {
        if let Some(v) = e.clarity     { add("Clarity2012", v.to_string()); }
        if let Some(v) = e.dehaze      { add("Dehaze", v.to_string()); }
    }

    format!(r#"<?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:crs="http://ns.adobe.com/camera-raw-settings/1.0/"
{}  </rdf:Description>
 </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>"#, attrs)
}
