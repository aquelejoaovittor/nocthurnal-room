import 'dart:io';
import 'dart:ui' as ui;

class Photo {
  final File file;
  String name;
  ui.Image? decodedImage;
  
  double exposure, contrast, highlights, shadows, whites, blacks;
  double temperature, tint, vibrance, saturation;
  double clarity, sharpening, texture, dehaze, noiseReduction;
  double vignette, grain;

  Photo({
    required this.file,
    required this.name,
    this.exposure = 0.0, this.contrast = 0.0, this.highlights = 0.0,
    this.shadows = 0.0, this.whites = 0.0, this.blacks = 0.0,
    this.temperature = 0.0, this.tint = 0.0, this.vibrance = 0.0, this.saturation = 0.0,
    this.clarity = 0.0, this.sharpening = 0.0, this.texture = 0.0, this.dehaze = 0.0, this.noiseReduction = 0.0,
    this.vignette = 0.0, this.grain = 0.0,
  });

  Future<void> loadImage() async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    decodedImage = frame.image;
  }
}
