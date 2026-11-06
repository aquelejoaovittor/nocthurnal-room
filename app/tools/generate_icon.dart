import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  // Fundo (Deep Navy Black do Nocthar)
  final bgPaint = Paint()..color = const Color(0xFF0A0D14);
  canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);

  // Círculo da Lente (Roxo)
  final lensPaint = Paint()
    ..color = const Color(0xFF9D4EDD)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 60.0;
  canvas.drawCircle(Offset(size / 2, size / 2), size * 0.3, lensPaint);

  // Detalhe Central (Ciano)
  final centerPaint = Paint()..color = const Color(0xFF00E5FF);
  canvas.drawCircle(Offset(size / 2, size / 2), size * 0.1, centerPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('assets/icon.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  print('Ícone gerado em: assets/icon.png');
}
