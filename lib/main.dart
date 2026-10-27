import 'package:flutter/material.dart';

import 'gallery_screen.dart';

void main() {
  runApp(const SketchPadApp());
}

class SketchPadApp extends StatelessWidget {
  const SketchPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SketchPad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const GalleryScreen(),
    );
  }
}
