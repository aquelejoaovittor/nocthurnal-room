import 'package:flutter/material.dart';
import 'screens/editor_screen.dart';

void main() {
  runApp(const NocthurnalRoomApp());
}

class NocthurnalRoomApp extends StatelessWidget {
  const NocthurnalRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nocthurnal Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181818),
        canvasColor: const Color(0xFF202020),
        dividerColor: const Color(0xFF2C2C2C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF282828),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF9D4EDD),
          thumbColor: Colors.white,
          inactiveTrackColor: Color(0xFF444444),
        ),
      ),
      home: const EditorScreen(),
    );
  }
}
