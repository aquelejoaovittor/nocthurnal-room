import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/photo.dart';
import '../widgets/right_panel.dart';
import '../widgets/left_panel.dart';
import '../widgets/logo.dart';
import '../widgets/image_viewport.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final List<Photo> _photos = [];
  int _selectedIndex = -1;

  Future<void> _pickPhotos() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      setState(() {
        _photos.addAll(result.paths.map((path) => Photo(
          file: File(path!),
          name: path.split('/').last,
        )));
        if (_selectedIndex == -1 && _photos.isNotEmpty) {
          _selectedIndex = 0;
          _loadCurrentImage();
        }
      });
    }
  }

  Future<void> _loadCurrentImage() async {
    if (_selectedIndex != -1 && _photos[_selectedIndex].decodedImage == null) {
      await _photos[_selectedIndex].loadImage();
      setState(() {});
    }
  }

  // Ponte com o Rust para Importar XMP
  Future<void> _importXmp() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xmp']);
    if (result != null) {
      final xmpPath = result.paths.first!;
      final outPath = xmpPath.replaceAll('.xmp', '.nroom');
      
      // Executa o binário do Rust (compilado na Fase 2)
      final process = await Process.run('../target/debug/nroom', ['import-xmp', xmpPath, '--out', outPath]);
      
      if (process.exitCode == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('XMP Importado! (Arquivo .nroom gerado)')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${process.stderr}')));
        }
      }
    }
  }

  // Renomear Foto
  Future<void> _renamePhoto(Photo photo) async {
    final controller = TextEditingController(text: photo.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Renomear Foto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => photo.name = newName);
    }
  }

  void _onPhotoSelected(int index) {
    setState(() => _selectedIndex = index);
    _loadCurrentImage();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final photo = _photos.isNotEmpty && _selectedIndex != -1 ? _photos[_selectedIndex] : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        title: const NoctharLogo(),
        actions: [
          TextButton.icon(
            onPressed: _importXmp,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('IMPORTAR XMP', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
          TextButton.icon(
            onPressed: _pickPhotos,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('IMPORTAR FOTO', style: TextStyle(color: Color(0xFF9D4EDD))),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile) LeftPanel(selectedPhoto: photo, onUpdate: () => setState(() {})),
          Expanded(child: ImageViewport(photo: photo)),
          if (!isMobile) RightPanel(selectedPhoto: photo, onUpdate: () => setState(() {})),
        ],
      ),
      bottomNavigationBar: _photos.isEmpty ? null : Container(
        height: 100,
        color: const Color(0xFF181818),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _onPhotoSelected(index),
              onDoubleTap: () => _renamePhoto(_photos[index]),
              child: Tooltip(
                message: 'Duplo clique para renomear',
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: index == _selectedIndex ? const Color(0xFF9D4EDD) : Colors.transparent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Expanded(child: Image.file(_photos[index].file, fit: BoxFit.cover)),
                      Container(
                        color: const Color(0xFF181818),
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        child: Text(_photos[index].name, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
