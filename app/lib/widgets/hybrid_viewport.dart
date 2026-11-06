import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/edit_pipeline.dart';
import 'shader_image.dart';

class HybridViewport extends StatefulWidget {
  final EditPipeline? pipeline;
  final bool isDrawing;
  final GlobalKey boundaryKey;
  final VoidCallback onUpdate;
  const HybridViewport({super.key, this.pipeline, this.isDrawing = false, required this.boundaryKey, required this.onUpdate});

  @override
  State<HybridViewport> createState() => _HybridViewportState();
}

class _HybridViewportState extends State<HybridViewport> {
  DrawingStroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    final p = widget.pipeline;
    if (p == null || p.baseImage == null) return const Center(child: Text('Importe uma imagem para começar', style: TextStyle(color: Colors.grey)));

    return Container(
      color: const Color(0xFF111111),
      child: RepaintBoundary(
        key: widget.boundaryKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTap: () { p.selectedElementId = null; widget.onUpdate(); },
              onPanStart: (details) {
                if (widget.isDrawing) { _currentStroke = DrawingStroke(points: [details.localPosition], color: Colors.purpleAccent); p.strokes.add(_currentStroke!); widget.onUpdate(); }
              },
              onPanUpdate: (details) {
                if (widget.isDrawing && _currentStroke != null) { _currentStroke!.points.add(details.localPosition); widget.onUpdate(); }
              },
              child: Stack(
                children: [
                  // Imagem Base com Transformação
                  Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(p.baseRotation)
                        ..scale(p.isFlippedHorizontal ? -1.0 : 1.0, p.isFlippedVertical ? -1.0 : 1.0),
                      child: ShaderImage(photo: p.baseImage!, adjustments: p.adjustments, onUpdate: widget.onUpdate),
                    ),
                  ),
                  CustomPaint(painter: _DrawingPainter(p.strokes), size: Size(constraints.maxWidth, constraints.maxHeight)),
                  
                  ...p.texts.map((text) {
                    final isSelected = p.selectedElementId == text.id;
                    return Positioned(
                      left: (constraints.maxWidth / 2) + text.x, top: (constraints.maxHeight / 2) + text.y,
                      child: GestureDetector(
                        onTap: () { p.selectedElementId = text.id; p.bringToFront(text.id); widget.onUpdate(); },
                        onPanUpdate: (details) { text.x += details.delta.dx; text.y += details.delta.dy; widget.onUpdate(); },
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2)),
                          padding: const EdgeInsets.all(4),
                          child: Text(text.text, style: TextStyle(color: text.color, fontSize: text.fontSize, fontWeight: text.fontWeight, fontFamily: text.fontFamily)),
                        ),
                      ),
                    );
                  }),

                  ...p.shapes.map((shape) {
                    final isSelected = p.selectedElementId == shape.id;
                    return Positioned(
                      left: (constraints.maxWidth / 2) + shape.x, top: (constraints.maxHeight / 2) + shape.y,
                      child: GestureDetector(
                        onTap: () { p.selectedElementId = shape.id; p.bringToFront(shape.id); widget.onUpdate(); },
                        onPanUpdate: (details) { shape.x += details.delta.dx; shape.y += details.delta.dy; widget.onUpdate(); },
                        child: Transform.rotate(
                          angle: shape.rotation,
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2)),
                            child: CustomPaint(size: Size(shape.size, shape.size), painter: ShapePainter(shape.type, shape.color)),
                          ),
                        ),
                      ),
                    );
                  }),

                  ...p.layers.map((layer) {
                    if (layer.image == null) return const SizedBox.shrink();
                    final isSelected = p.selectedElementId == layer.id;
                    return Positioned(
                      left: (constraints.maxWidth / 2) - (layer.image!.width / 2 * layer.scale) + layer.x,
                      top: (constraints.maxHeight / 2) - (layer.image!.height / 2 * layer.scale) + layer.y,
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent && isSelected) {
                            setState(() { layer.scale -= pointerSignal.scrollDelta.dy * 0.005; if (layer.scale < 0.1) layer.scale = 0.1; });
                          }
                        },
                        child: GestureDetector(
                          onTap: () { p.selectedElementId = layer.id; p.bringToFront(layer.id); widget.onUpdate(); },
                          onPanUpdate: (details) { layer.x += details.delta.dx; layer.y += details.delta.dy; widget.onUpdate(); },
                          child: Transform.rotate(
                            angle: layer.rotation,
                            child: Container(
                              decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2)),
                              child: Opacity(opacity: layer.opacity, child: Image.file(layer.file, width: layer.image!.width * layer.scale, height: layer.image!.height * layer.scale)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final ShapeType type; final Color color;
  ShapePainter(this.type, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final cx = size.width / 2; final cy = size.height / 2; final r = size.width / 2;
    switch (type) {
      case ShapeType.circle: canvas.drawCircle(Offset(cx, cy), r, paint); break;
      case ShapeType.square: canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint); break;
      case ShapeType.triangle: path.moveTo(cx, 0); path.lineTo(size.width, size.height); path.lineTo(0, size.height); path.close(); canvas.drawPath(path, paint); break;
      case ShapeType.star:
        for (int i = 0; i < 5; i++) { path.lineTo(cx + r * math.cos((18 + i * 72) * math.pi / 180), cy - r * math.sin((18 + i * 72) * math.pi / 180)); path.lineTo(cx + r * 0.4 * math.cos((54 + i * 72) * math.pi / 180), cy - r * 0.4 * math.sin((54 + i * 72) * math.pi / 180)); }
        path.close(); canvas.drawPath(path, paint); break;
      case ShapeType.heart:
        path.moveTo(cx, size.height * 0.3); path.cubicTo(size.width * 1.2, 0, cx, size.height * 0.8, cx, size.height); path.cubicTo(cx, size.height * 0.8, -size.width * 0.2, 0, cx, size.height * 0.3); canvas.drawPath(path, paint); break;
      case ShapeType.hexagon:
        for (int i = 0; i < 6; i++) { path.lineTo(cx + r * math.cos(i * math.pi / 3), cy + r * math.sin(i * math.pi / 3)); } path.close(); canvas.drawPath(path, paint); break;
    }
  }
  @override
  bool shouldRepaint(ShapePainter oldDelegate) => true;
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  _DrawingPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()..color = stroke.color..strokeWidth = stroke.strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      final path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        for (int i = 1; i < stroke.points.length; i++) { path.lineTo(stroke.points[i].dx, stroke.points[i].dy); }
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
