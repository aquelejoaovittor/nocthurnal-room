import 'package:flutter/material.dart';
import '../core/edit_pipeline.dart';
import 'histogram.dart';

class HybridRightPanel extends StatefulWidget {
  final bool isCreativeMode;
  final EditPipeline? pipeline;
  final VoidCallback onUpdate;
  final VoidCallback onEditText;
  const HybridRightPanel({super.key, required this.isCreativeMode, this.pipeline, required this.onUpdate, required this.onEditText});

  @override
  State<HybridRightPanel> createState() => _HybridRightPanelState();
}

class _HybridRightPanelState extends State<HybridRightPanel> {
  final Map<String, bool> _expanded = {'LUZ': true, 'COR': false, 'DETALHE': false, 'EFEITOS': false, 'TRANSFORMAÇÃO': true, 'PROPRIEDADES': true};

  Widget _buildSlider(String label, double value, Function(double) onChanged, {double min = -100, double max = 100}) {
    return GestureDetector(
      onDoubleTap: () { onChanged(0.0); widget.onUpdate(); }, // Duplo clique reseta
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 12.0),
        child: Row(children: [
          SizedBox(width: 65, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70))),
          Expanded(child: Slider(value: value, min: min, max: max, onChanged: (val) { onChanged(val); widget.onUpdate(); })),
          SizedBox(width: 25, child: Text(value.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final isExpanded = _expanded[title] ?? false;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded[title] = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF252525),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 14, color: Colors.grey),
            ]),
          ),
        ),
        if (isExpanded) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: children)),
        const Divider(color: Color(0xFF333333), height: 1),
      ],
    );
  }

  Widget _buildColorPicker(Color current, Function(Color) onColor) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: Colors.primaries.map((c) => GestureDetector(
        onTap: () { onColor(c); widget.onUpdate(); },
        child: Container(width: 22, height: 22, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: current == c ? Colors.white : Colors.transparent, width: 2))),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pipeline;
    final adjustments = p?.adjustments ?? LightroomAdjustments();
    final selected = p?.selectedElementId;
    
    CreativeText? selText;
    CreativeShape? selShape;
    if (selected != null && p != null) {
      selText = p.texts.where((e) => e.id == selected).firstOrNull;
      selShape = p.shapes.where((e) => e.id == selected).firstOrNull;
    }

    return Container(
      width: 280, color: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          RealHistogram(imageFile: p?.baseImageFile),
          
          if (!widget.isCreativeMode) ...[
            _buildSection('LUZ', [
              _buildSlider('Exposição', adjustments.exposure, (v) { if(p != null) p.adjustments.exposure = v; }, min: -5, max: 5),
              _buildSlider('Contraste', adjustments.contrast, (v) { if(p != null) p.adjustments.contrast = v; }),
              _buildSlider('Realces', adjustments.highlights, (v) { if(p != null) p.adjustments.highlights = v; }),
              _buildSlider('Sombras', adjustments.shadows, (v) { if(p != null) p.adjustments.shadows = v; }),
              _buildSlider('Brancos', adjustments.whites, (v) { if(p != null) p.adjustments.whites = v; }),
              _buildSlider('Pretos', adjustments.blacks, (v) { if(p != null) p.adjustments.blacks = v; }),
            ]),
            _buildSection('COR', [
              _buildSlider('Temperatura', adjustments.temperature, (v) { if(p != null) p.adjustments.temperature = v; }),
              _buildSlider('Matiz', adjustments.tint, (v) { if(p != null) p.adjustments.tint = v; }),
              _buildSlider('Vibração', adjustments.vibrance, (v) { if(p != null) p.adjustments.vibrance = v; }),
              _buildSlider('Saturação', adjustments.saturation, (v) { if(p != null) p.adjustments.saturation = v; }),
            ]),
            _buildSection('DETALHE', [
              _buildSlider('Clareza', adjustments.clarity, (v) { if(p != null) p.adjustments.clarity = v; }),
            ]),
            _buildSection('EFEITOS', [
              _buildSlider('Vinheta', adjustments.vignette, (v) { if(p != null) p.adjustments.vignette = v; }),
            ]),
            _buildSection('TRANSFORMAÇÃO', [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.rotate_left), onPressed: () { if (p != null) { p.baseRotation -= 1.5708; widget.onUpdate(); } }),
                IconButton(icon: const Icon(Icons.rotate_right), onPressed: () { if (p != null) { p.baseRotation += 1.5708; widget.onUpdate(); } }),
                IconButton(icon: const Icon(Icons.flip), onPressed: () { if (p != null) { p.isFlippedHorizontal = !p.isFlippedHorizontal; widget.onUpdate(); } }),
                IconButton(icon: const Icon(Icons.flip_camera_android), onPressed: () { if (p != null) { p.isFlippedVertical = !p.isFlippedVertical; widget.onUpdate(); } }),
              ]),
            ]),
          ] else if (p != null) ...[
            if (selText != null) ...[
              _buildSection('PROPRIEDADES DO TEXTO', [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ElevatedButton.icon(onPressed: widget.onEditText, icon: const Icon(Icons.edit, size: 14), label: const Text('Editar Palavras'))),
                const SizedBox(height: 8),
                _buildSlider('Tamanho', selText.fontSize, (v) => selText!.fontSize = v, min: 10, max: 200),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Cor:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildColorPicker(selText.color, (c) => selText!.color = c)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Fonte:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selText.fontFamily, isExpanded: true, dropdownColor: const Color(0xFF252525), style: const TextStyle(fontSize: 11),
                    items: ['Roboto', 'serif', 'cursive', 'monospace'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (f) { if (f != null) { selText!.fontFamily = f; widget.onUpdate(); } },
                  ),
                ),
              ])
            ] else if (selShape != null) ...[
              _buildSection('PROPRIEDADES DA FORMA', [
                _buildSlider('Tamanho', selShape.size, (v) => selShape!.size = v, min: 20, max: 400),
                _buildSlider('Rotação', selShape.rotation, (v) => selShape!.rotation = v, min: -3.14, max: 3.14),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('Cor:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildColorPicker(selShape.color, (c) => selShape!.color = c)),
              ])
            ] else ...[
              _buildSection('CAMADAS E BLEND', [
                ...p.layers.map((layer) => Column(children: [
                  _buildSlider('Opacidade', layer.opacity * 100, (v) => layer.opacity = v / 100, min: 0, max: 100),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<LayerBlendMode>(
                      value: layer.blendMode, isExpanded: true, dropdownColor: const Color(0xFF252525), style: const TextStyle(fontSize: 11, color: Colors.white),
                      items: LayerBlendMode.values.map((mode) => DropdownMenuItem(value: mode, child: Text(mode.name.toUpperCase()))).toList(),
                      onChanged: (mode) { if (mode != null) { layer.blendMode = mode; widget.onUpdate(); } },
                    ),
                  ),
                  const Divider(),
                ])),
              ]),
            ]
          ]
        ],
      ),
    );
  }
}
