import 'package:flutter/material.dart';
import '../models/photo.dart';
import 'histogram.dart';

class RightPanel extends StatefulWidget {
  final Photo? selectedPhoto;
  final VoidCallback onUpdate;
  const RightPanel({super.key, this.selectedPhoto, required this.onUpdate});

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  final Map<String, bool> _expanded = {
    'LUZ': true,
    'COR': false,
    'DETALHE': false,
    'EFEITOS': false,
    'LENTE': false,
    'MÁSCARAS': false,
  };

  Widget _buildSlider(String label, double value, Function(double) onChanged, {double min = -100, double max = 100}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
              child: Slider(
                value: value, min: min, max: max,
                onChanged: (val) { onChanged(val); widget.onUpdate(); },
              ),
            ),
          ),
          SizedBox(width: 30, child: Text(value.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF202020),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (isExpanded) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: children)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.selectedPhoto;

    return Container(
      width: 300,
      color: const Color(0xFF181818),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          RealHistogram(imageFile: photo?.file),
          
          if (photo != null) ...[
            _buildSection('LUZ', [
              _buildSlider('Exposição', photo.exposure, (v) => photo.exposure = v, min: -5, max: 5),
              _buildSlider('Contraste', photo.contrast, (v) => photo.contrast = v),
              _buildSlider('Realces', photo.highlights, (v) => photo.highlights = v),
              _buildSlider('Sombras', photo.shadows, (v) => photo.shadows = v),
            ]),
            _buildSection('COR', [
              _buildSlider('Temperatura', photo.temperature, (v) => photo.temperature = v),
              _buildSlider('Matiz', photo.tint, (v) => photo.tint = v),
              _buildSlider('Saturação', photo.saturation, (v) => photo.saturation = v),
            ]),
            _buildSection('DETALHE', [
              _buildSlider('Clareza', photo.clarity, (v) => photo.clarity = v),
              _buildSlider('Nitidez', photo.sharpening, (v) => photo.sharpening = v),
              _buildSlider('Redução de Ruído', photo.noiseReduction, (v) => photo.noiseReduction = v),
            ]),
            _buildSection('EFEITOS', [
              _buildSlider('Vinheta', photo.vignette, (v) => photo.vignette = v),
              _buildSlider('Granulado', photo.grain, (v) => photo.grain = v),
            ]),
            _buildSection('LENTE', [
              const Padding(padding: EdgeInsets.all(16), child: Text('Correção de Lente (Em breve)', style: TextStyle(color: Colors.grey, fontSize: 11))),
            ]),
            _buildSection('MÁSCARAS', [
              const Padding(padding: EdgeInsets.all(16), child: Text('Ferramentas de Máscara (Em breve)', style: TextStyle(color: Colors.grey, fontSize: 11))),
            ]),
          ] else
            const Padding(padding: EdgeInsets.all(16), child: Text('Selecione uma foto', style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}
