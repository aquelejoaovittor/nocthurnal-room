import 'package:flutter/material.dart';
import 'screens/workspace_screen.dart';

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
        canvasColor: const Color(0xFF1A1A1A),
        dividerColor: const Color(0xFF333333),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF252525),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF888888),
          thumbColor: Colors.white,
          inactiveTrackColor: Color(0xFF333333),
          trackHeight: 2,
        ),
      ),
      home: const WorkspaceScreen(),
    );
  }
}
