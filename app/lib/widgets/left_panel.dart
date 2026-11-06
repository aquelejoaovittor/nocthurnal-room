import 'package:flutter/material.dart';
import '../core/edit_pipeline.dart';

class LeftPanel extends StatefulWidget {
  final bool isCreativeMode;
  final EditPipeline? pipeline;
  final Function(String, dynamic) onToolSelected;
  final VoidCallback onAddLayer;
  final VoidCallback onImportXmp;
  final Function(String) onFilterSelected;
  const LeftPanel({super.key, required this.isCreativeMode, this.pipeline, required this.onToolSelected, required this.onAddLayer, required this.onImportXmp, required this.onFilterSelected});

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  final Map<String, bool> _expanded = {'NAVEGADOR': true, 'FILTROS': true, 'HISTÓRICO': false, 'FERRAMENTAS': true, 'FORMAS': true};

  Widget _buildSection(String title, List<Widget> children) {
    final isExpanded = _expanded[title] ?? false;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded[title] = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF252525),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
              Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 14, color: Colors.grey),
            ]),
          ),
        ),
        if (isExpanded) Padding(padding: const EdgeInsets.all(8.0), child: Column(children: children)),
        const Divider(color: Color(0xFF333333), height: 1),
      ],
    );
  }

  Widget _buildToolItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, color: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSection('NAVEGADOR', [
            Container(
              height: 120, width: double.infinity, color: const Color(0xFF111111),
              child: widget.pipeline?.baseImage != null
                  ? Image.file(widget.pipeline!.baseImageFile, fit: BoxFit.contain)
                  : const Center(child: Text('Preview', style: TextStyle(color: Colors.grey, fontSize: 10))),
            ),
          ]),
          if (!widget.isCreativeMode) ...[
            _buildSection('FILTROS RÁPIDOS', [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _filterBtn('Original', () => widget.onFilterSelected('reset')),
                _filterBtn('Preto & Branco', () => widget.onFilterSelected('bw')),
                _filterBtn('Sépia', () => widget.onFilterSelected('sepia')),
                _filterBtn('Cyberpunk', () => widget.onFilterSelected('neon')),
              ]),
            ]),
            _buildSection('HISTÓRICO', [
              _buildToolItem('Importar XMP', Icons.file_upload, widget.onImportXmp),
            ]),
          ] else ...[
            _buildSection('FERRAMENTAS', [
              _buildToolItem('Adicionar Texto', Icons.text_fields, () => widget.onToolSelected('text', null)),
              _buildToolItem('Importar Sticker', Icons.emoji_emotions_outlined, widget.onAddLayer),
              _buildToolItem('Desenho', Icons.brush, () => widget.onToolSelected('draw', null)),
            ]),
            _buildSection('FORMAS', [
              Wrap(spacing: 8, runSpacing: 8, children: ShapeType.values.map((type) {
                return InkWell(
                  onTap: () => widget.onToolSelected('shape', type),
                  child: Container(
                    width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(4)),
                    child: Icon(type == ShapeType.circle ? Icons.circle : type == ShapeType.square ? Icons.square : type == ShapeType.triangle ? Icons.change_history : type == ShapeType.star ? Icons.star : type == ShapeType.heart ? Icons.favorite : Icons.hexagon, color: Colors.white70, size: 18),
                  ),
                );
              }).toList()),
            ]),
          ]
        ],
      ),
    );
  }

  Widget _filterBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
      ),
    );
  }
}
