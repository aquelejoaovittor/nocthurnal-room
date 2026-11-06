import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum LayerBlendMode { normal, multiply, screen, overlay, darken, lighten }
enum ShapeType { circle, square, triangle, star, heart, hexagon }

class CreativeElement {
  final String id;
  CreativeElement() : id = DateTime.now().microsecondsSinceEpoch.toString();
}

class CreativeText extends CreativeElement {
  String text; double x, y, fontSize; Color color; FontWeight fontWeight; String fontFamily;
  CreativeText({required this.text, this.x = 0.0, this.y = 0.0, this.fontSize = 40.0, this.color = Colors.white, this.fontWeight = FontWeight.bold, this.fontFamily = 'Roboto'}) : super();
}

class CreativeShape extends CreativeElement {
  ShapeType type; double x, y, size, rotation; Color color;
  CreativeShape({required this.type, this.x = 0.0, this.y = 0.0, this.size = 100.0, this.rotation = 0.0, this.color = const Color(0xFF9D4EDD)}) : super();
}

class DrawingStroke extends CreativeElement {
  final List<Offset> points; Color color; double strokeWidth;
  DrawingStroke({required this.points, required this.color, this.strokeWidth = 5.0}) : super();
}

class CreativeLayer extends CreativeElement {
  final File file; ui.Image? image; double opacity; LayerBlendMode blendMode; double x, y, scale, rotation;
  CreativeLayer({required this.file, this.image, this.opacity = 1.0, this.blendMode = LayerBlendMode.normal, this.x = 0.0, this.y = 0.0, this.scale = 1.0, this.rotation = 0.0}) : super();
}

class LightroomAdjustments {
  double exposure = 0.0, contrast = 0.0, highlights = 0.0, shadows = 0.0, whites = 0.0, blacks = 0.0;
  double temperature = 0.0, tint = 0.0, vibrance = 0.0, saturation = 0.0;
  double texture = 0.0, clarity = 0.0, dehaze = 0.0, sharpening = 0.0, noiseReduction = 0.0;
  double vignette = 0.0, grain = 0.0;

  // Snapshot para Desfazer
  LightroomAdjustments clone() {
    return LightroomAdjustments()
      ..exposure = exposure ..contrast = contrast ..highlights = highlights ..shadows = shadows ..whites = whites ..blacks = blacks
      ..temperature = temperature ..tint = tint ..vibrance = vibrance ..saturation = saturation
      ..texture = texture ..clarity = clarity ..dehaze = dehaze ..sharpening = sharpening ..noiseReduction = noiseReduction
      ..vignette = vignette ..grain = grain;
  }
}

class EditPipeline {
  final File baseImageFile;
  ui.Image? baseImage;
  LightroomAdjustments adjustments;
  
  // Transformação Base
  double baseRotation = 0.0;
  bool isFlippedHorizontal = false;
  bool isFlippedVertical = false;

  String? selectedElementId;
  final List<CreativeText> texts = [];
  final List<CreativeShape> shapes = [];
  final List<DrawingStroke> strokes = [];
  final List<CreativeLayer> layers = [];

  EditPipeline({required this.baseImageFile, this.baseImage, required this.adjustments});

  Future<void> loadBaseImage() async {
    final bytes = await baseImageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    baseImage = frame.image;
  }

  void bringToFront(String id) {
    final text = texts.where((e) => e.id == id).firstOrNull;
    if (text != null) { texts.remove(text); texts.add(text); return; }
    final shape = shapes.where((e) => e.id == id).firstOrNull;
    if (shape != null) { shapes.remove(shape); shapes.add(shape); return; }
    final layer = layers.where((e) => e.id == id).firstOrNull;
    if (layer != null) { layers.remove(layer); layers.add(layer); return; }
  }

  void removeElement(String id) {
    texts.removeWhere((e) => e.id == id); shapes.removeWhere((e) => e.id == id);
    strokes.removeWhere((e) => e.id == id); layers.removeWhere((e) => e.id == id);
    if (selectedElementId == id) selectedElementId = null;
  }
}
