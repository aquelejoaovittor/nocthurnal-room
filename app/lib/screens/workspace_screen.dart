import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../core/edit_pipeline.dart';
import '../widgets/hybrid_viewport.dart';
import '../widgets/hybrid_right_panel.dart';
import '../widgets/left_panel.dart';
import '../widgets/logo.dart';

enum AppMode { reveal, creative }

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  AppMode _currentMode = AppMode.reveal;
  EditPipeline? _pipeline;
  final List<EditPipeline> _catalog = [];
  int _selectedIndex = -1;
  bool _isDrawing = false;
  final GlobalKey _boundaryKey = GlobalKey();

  // Histórico Undo/Redo
  final List<LightroomAdjustments> _history = [];
  int _historyIndex = -1;

  void _saveHistory() {
    if (_pipeline == null) return;
    if (_historyIndex < _history.length - 1) { _history.removeRange(_historyIndex + 1, _history.length); }
    _history.add(_pipeline!.adjustments.clone());
    _historyIndex = _history.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _pipeline?.adjustments = _history[_historyIndex];
      setState(() {});
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _pipeline?.adjustments = _history[_historyIndex];
      setState(() {});
    }
  }

  Future<void> _importBaseImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (result != null) {
      for (var path in result.paths) {
        final pipeline = EditPipeline(baseImageFile: File(path!), adjustments: LightroomAdjustments());
        await pipeline.loadBaseImage();
        _catalog.add(pipeline);
      }
      setState(() { if (_selectedIndex == -1 && _catalog.isNotEmpty) _selectedIndex = 0; _pipeline = _catalog[_selectedIndex]; _saveHistory(); });
    }
  }

  Future<void> _addLayer() async {
    if (_pipeline == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (result != null) {
      for (var path in result.paths) {
        final file = File(path!);
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        setState(() { _pipeline!.layers.add(CreativeLayer(file: file, image: frame.image)); });
      }
    }
  }

  Future<void> _exportImage() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final savePath = await FilePicker.platform.saveFile(dialogTitle: 'Salvar', fileName: 'nocthurnal_export.png', type: FileType.image);
      if (savePath != null) {
        await File(savePath).writeAsBytes(pngBytes);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagem exportada!')));
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'))); }
  }

  Future<void> _editTextDialog(CreativeText text) async {
    final controller = TextEditingController(text: text.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525), title: const Text('Editar Texto'),
        content: TextField(controller: controller, autofocus: true, style: const TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Salvar'))],
      ),
    );
    if (result != null && result.isNotEmpty) { setState(() { text.text = result; }); }
  }

  void _handleTool(String tool, dynamic data) {
    if (_pipeline == null) return;
    setState(() {
      if (tool == 'text') {
        final newText = CreativeText(text: 'Novo Texto'); _pipeline!.texts.add(newText); _pipeline!.selectedElementId = newText.id; _editTextDialog(newText);
      } else if (tool == 'shape') {
        final newShape = CreativeShape(type: data as ShapeType, size: 100); _pipeline!.shapes.add(newShape); _pipeline!.selectedElementId = newShape.id;
      } else if (tool == 'draw') { _isDrawing = !_isDrawing; }
    });
  }

  // Aplica Filtros Rápidos no Painel Esquerdo
  void _applyFilter(String filterName) {
    if (_pipeline == null) return;
    setState(() {
      final a = _pipeline!.adjustments;
      if (filterName == 'bw') { a.saturation = -100; a.contrast = 20; }
      else if (filterName == 'sepia') { a.temperature = 40; a.saturation = -30; a.contrast = 10; }
      else if (filterName == 'neon') { a.temperature = -50; a.tint = 40; a.saturation = 80; a.contrast = 30; }
      else if (filterName == 'reset') { a.exposure = 0; a.contrast = 0; a.temperature = 0; a.tint = 0; a.saturation = 0; }
      _saveHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    // Atalhos de Teclado Globais
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Row(children: [
              const NoctharLogo(), const SizedBox(width: 32),
              SegmentedButton<AppMode>(
                segments: const [
                  ButtonSegment(value: AppMode.reveal, label: Text('Revelar'), icon: Icon(Icons.camera)),
                  ButtonSegment(value: AppMode.creative, label: Text('Criativo'), icon: Icon(Icons.auto_awesome)),
                ],
                selected: {_currentMode}, onSelectionChanged: (s) => setState(() => _currentMode = s.first),
              )
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.undo), onPressed: _undo, tooltip: 'Desfazer (Ctrl+Z)'),
              IconButton(icon: const Icon(Icons.redo), onPressed: _redo, tooltip: 'Refazer (Ctrl+Y)'),
              if (_pipeline == null) TextButton.icon(onPressed: _importBaseImage, icon: const Icon(Icons.image), label: const Text('Importar')),
              if (_pipeline != null) TextButton.icon(onPressed: _exportImage, icon: const Icon(Icons.save_alt, color: Colors.greenAccent), label: const Text('Exportar', style: TextStyle(color: Colors.greenAccent))),
              const SizedBox(width: 16),
            ],
          ),
          body: isMobile ? const Center(child: Text('Mobile em breve')) : Column(
            children: [
              Expanded(child: Row(
                children: [
                  LeftPanel(isCreativeMode: _currentMode == AppMode.creative, pipeline: _pipeline, onToolSelected: _handleTool, onAddLayer: _addLayer, onImportXmp: () {}, onFilterSelected: _applyFilter),
                  Expanded(child: HybridViewport(pipeline: _pipeline, isDrawing: _isDrawing, boundaryKey: _boundaryKey, onUpdate: () { setState(() {}); _saveHistory(); })),
                  HybridRightPanel(isCreativeMode: _currentMode == AppMode.creative, pipeline: _pipeline, onUpdate: () { setState(() {}); _saveHistory(); }, onEditText: () {
                      final sel = _pipeline?.texts.where((e) => e.id == _pipeline?.selectedElementId).firstOrNull;
                      if (sel != null) _editTextDialog(sel);
                  }),
                ],
              )),
              _buildFilmstrip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilmstrip() {
    if (_catalog.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 90, color: const Color(0xFF111111),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), itemCount: _catalog.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => setState(() { _selectedIndex = index; _pipeline = _catalog[index]; _saveHistory(); }),
            child: Container(
              margin: const EdgeInsets.only(right: 6), width: 80,
              decoration: BoxDecoration(border: Border.all(color: index == _selectedIndex ? const Color(0xFF4CAF50) : Colors.transparent, width: 2)),
              child: Image.file(_catalog[index].baseImageFile, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
