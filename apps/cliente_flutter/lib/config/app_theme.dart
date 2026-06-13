import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // La paleta vive centralizada para que login, registro y pantallas internas
  // compartan el mismo lenguaje visual. No son colores aislados: describen
  // fondo, superficies, jerarquía de texto y bordes reutilizados.
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF1A1A1A);
  static const Color mutedInk = Color(0xFF5C5C5C);
  static const Color line = Color(0xFFE5E5E5);

  static ThemeData get lightTheme {
    // Partimos de un ThemeData base y lo refinamos para documentar mejor qué
    // decisiones visuales son propias de la app y cuáles siguen siendo Material.
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        brightness: Brightness.light,
        primary: ink,
        surface: background,
      ),
    );

    return base.copyWith(
      // Todo este bloque funciona como contrato visual compartido: si una
      // pantalla usa widgets estándar, hereda el mismo feedback visual y reduce
      // inconsistencias de UX entre flujos.
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ink),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      dividerColor: line,
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: ink,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.6, color: ink),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.6, color: mutedInk),
        labelLarge: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
