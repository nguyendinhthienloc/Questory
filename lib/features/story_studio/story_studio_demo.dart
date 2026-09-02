import 'package:flutter/material.dart';

import 'presentation/story_studio_screen.dart';

/// Development-only entry point for exercising Story Studio independently.
///
/// Run with:
/// `flutter run -t lib/features/story_studio/story_studio_demo.dart`
void main() {
  runApp(const StoryStudioDemoApp());
}

class StoryStudioDemoApp extends StatelessWidget {
  const StoryStudioDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questory Story Studio Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2457D6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F0E3),
        useMaterial3: true,
      ),
      home: const StoryStudioScreen(),
    );
  }
}
