import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/edit_pipeline.dart';

class ShaderImage extends StatefulWidget {
  final ui.Image photo;
  final LightroomAdjustments adjustments;
  final VoidCallback onUpdate;
  const ShaderImage({super.key, required this.photo, required this.adjustments, required this.onUpdate});

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
    if (_shader == null) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        _shader!.setFloat(0, constraints.maxWidth);
        _shader!.setFloat(1, constraints.maxHeight);
        _shader!.setFloat(2, widget.photo.width.toDouble());
        _shader!.setFloat(3, widget.photo.height.toDouble());
        
        _shader!.setFloat(4, widget.adjustments.exposure / 5.0);
        _shader!.setFloat(5, 1.0 + (widget.adjustments.contrast * 0.01));
        _shader!.setFloat(6, widget.adjustments.highlights);
        _shader!.setFloat(7, widget.adjustments.shadows);
        _shader!.setFloat(8, widget.adjustments.whites);
        _shader!.setFloat(9, widget.adjustments.blacks);
        _shader!.setFloat(10, widget.adjustments.temperature / 100.0);
        _shader!.setFloat(11, widget.adjustments.tint / 100.0);
        _shader!.setFloat(12, widget.adjustments.saturation / 100.0);
        _shader!.setFloat(13, widget.adjustments.clarity / 100.0);
        _shader!.setFloat(14, widget.adjustments.vignette / 100.0);

        _shader!.setImageSampler(0, widget.photo);
        
        return CustomPaint(size: Size.infinite, painter: _ShaderPainter(_shader!));
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
