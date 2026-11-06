import 'package:flutter/material.dart';

class NoctharLogo extends StatelessWidget {
  const NoctharLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.camera, color: const Color(0xFF9D4EDD), size: 20),
        const SizedBox(width: 8),
        const Text(
          'NOCTHURNAL ROOM',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ],
    );
  }
}
