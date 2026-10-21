import 'package:flutter/material.dart';

class CrediColors {
  static const vino = Color(0xFF8E1D3C);
  static const vinoOscuro = Color(0xFF111827);
  static const fondo = Color(0xFFF3F4F8);
  static const texto = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const verde = Color(0xFF16803C);
  static const verdeSuave = Color(0xFFE7F6EC);
  static const rojoSuave = Color(0xFFFDE8EC);
  static const rosaSuave = Color(0xFFF8E8EC);
}

ThemeData crediTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: CrediColors.fondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CrediColors.vino,
      primary: CrediColors.vino,
      surface: Colors.white,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CrediColors.vino, width: 1.4),
      ),
    ),
  );
}
