import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/photo.dart';

class ShaderImage extends StatefulWidget {
  final Photo photo;
  const ShaderImage({super.key, required this.photo});

  @override
  State<ShaderImage> createState() => _ShaderImageState();
}

class _ShaderImageState extends State<ShaderImage> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/adjustments.frag');
    setState(() => _shader = program.fragmentShader());
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || widget.photo.decodedImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _shader!.setFloat(0, constraints.maxWidth);
        _shader!.setFloat(1, constraints.maxHeight);
        _shader!.setFloat(2, widget.photo.decodedImage!.width.toDouble());
        _shader!.setFloat(3, widget.photo.decodedImage!.height.toDouble());

        _shader!.setFloat(4, widget.photo.exposure / 5.0);
        _shader!.setFloat(5, 1.0 + (widget.photo.contrast * 0.01));
        _shader!.setFloat(6, widget.photo.temperature / 100.0);
        _shader!.setFloat(7, widget.photo.tint / 100.0);
        _shader!.setFloat(8, widget.photo.saturation / 100.0);

        _shader!.setImageSampler(0, widget.photo.decodedImage!);

        return CustomPaint(
          size: Size.infinite,
          painter: _ShaderPainter(_shader!),
        );
      }
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  _ShaderPainter(this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShaderPainter oldDelegate) => true;
}
