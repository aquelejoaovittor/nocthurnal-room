import 'package:flutter/material.dart';

class NoctharLogo extends StatelessWidget {
  final double size;
  const NoctharLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.camera, size: size, color: const Color(0xFF9D4EDD)),
        const SizedBox(width: 8),
        Text(
          'NOCTHURNAL ROOM',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
