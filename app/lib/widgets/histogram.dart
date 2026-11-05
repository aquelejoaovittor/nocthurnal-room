import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RealHistogram extends StatefulWidget {
  final File? imageFile;
  const RealHistogram({super.key, this.imageFile});

  @override
  State<RealHistogram> createState() => _RealHistogramState();
}

class _RealHistogramState extends State<RealHistogram> {
  List<int> rHist = List.filled(256, 0);
  List<int> gHist = List.filled(256, 0);
  List<int> bHist = List.filled(256, 0);

  @override
  void didUpdateWidget(covariant RealHistogram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFile != oldWidget.imageFile) _calculateHistogram();
  }

  @override
  void initState() {
    super.initState();
    if (widget.imageFile != null) _calculateHistogram();
  }

  Future<void> _calculateHistogram() async {
    if (widget.imageFile == null) return;
    try {
      final bytes = await widget.imageFile!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (byteData == null) return;
      final pixels = byteData.buffer.asUint8List();
      
      List<int> r = List.filled(256, 0);
      List<int> g = List.filled(256, 0);
      List<int> b = List.filled(256, 0);

      // Pula pixels para performance (amostragem)
      for (int i = 0; i < pixels.length; i += 16) {
        r[pixels[i]]++;
        g[pixels[i + 1]]++;
        b[pixels[i + 2]]++;
      }

      setState(() {
        rHist = r;
        gHist = g;
        bHist = b;
      });
    } catch (e) {
      debugPrint('Erro no histograma: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0A0D14), border: Border.all(color: const Color(0xFF1E2633))),
      child: widget.imageFile == null 
        ? const Center(child: Text('Histograma', style: TextStyle(color: Colors.grey, fontSize: 10)))
        : CustomPaint(painter: HistogramPainter(rHist, gHist, bHist), size: Size.infinite),
    );
  }
}

class HistogramPainter extends CustomPainter {
  final List<int> r, g, b;
  HistogramPainter(this.r, this.g, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [r, g, b].expand((e) => e).reduce((a, b) => a > b ? a : b).toDouble();
    
    void drawChannel(List<int> hist, Color color) {
      final paint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.screen;

      final path = Path()..moveTo(0, size.height);
      for (int i = 0; i < 256; i++) {
        final x = (i / 255.0) * size.width;
        final y = size.height - ((hist[i] / maxVal) * size.height);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    drawChannel(r, Colors.red);
    drawChannel(g, Colors.green);
    drawChannel(b, Colors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
