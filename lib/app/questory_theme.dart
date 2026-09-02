import 'package:flutter/material.dart';

abstract final class QuestoryColors {
  static const paper = Color(0xFFF7F1E3);
  static const ink = Color(0xFF171717);
  static const coral = Color(0xFFFF6B5E);
  static const cobalt = Color(0xFF3157C8);
  static const teal = Color(0xFF0B7A75);
  static const yellow = Color(0xFFFFD447);
  static const white = Color(0xFFFFFFFF);
}

ThemeData buildQuestoryTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: QuestoryColors.cobalt,
      primary: QuestoryColors.cobalt,
      secondary: QuestoryColors.coral,
      surface: QuestoryColors.paper,
    ),
    scaffoldBackgroundColor: QuestoryColors.paper,
    fontFamily: 'Noto Sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: QuestoryColors.paper,
      foregroundColor: QuestoryColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: QuestoryColors.ink,
        foregroundColor: QuestoryColors.white,
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    useMaterial3: true,
  );
}
