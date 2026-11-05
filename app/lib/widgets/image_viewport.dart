import 'package:flutter/material.dart';
import '../models/photo.dart';
import 'shader_image.dart';

class ImageViewport extends StatelessWidget {
  final Photo? photo;
  const ImageViewport({super.key, this.photo});

  @override
  Widget build(BuildContext context) {
    if (photo == null || photo!.decodedImage == null) {
      return const Center(child: Text('Nenhuma foto selecionada', style: TextStyle(color: Colors.grey)));
    }

    return Container(
      color: const Color(0xFF111111),
      // O InteractiveViewer permite dar zoom com a rodinha do mouse e arrastar (Pan)
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: ShaderImage(photo: photo!),
        ),
      ),
    );
  }
}
