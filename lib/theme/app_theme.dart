import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color fondo = Color(0xFFFFF6EE);
  static const Color fondoClaro = Color(0xFFFFFBF5);
  static const Color naranjaSuave = Color(0xFFE89B6A);
  static const Color terracota = Color(0xFFD27D55);
  static const Color textoOscuro = Color(0xFF3A2A22);
  static const Color textoSuave = Color(0xFF7A6358);
  static const Color cremaTarjeta = Color(0xFFFFEFE0);
  static const Color verdeSuave = Color(0xFF8FAA80);

  // Dark mode
  static const Color fondoDark = Color(0xFF1B1411);
  static const Color fondoClaroDark = Color(0xFF241B17);
  static const Color cremaTarjetaDark = Color(0xFF2E221C);
  static const Color textoOscuroDark = Color(0xFFF3E7DC);
  static const Color textoSuaveDark = Color(0xFFB59A8A);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fondo,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracota,
        secondary: AppColors.naranjaSuave,
        surface: AppColors.fondoClaro,
        onPrimary: Colors.white,
        onSurface: AppColors.textoOscuro,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textoOscuro,
        displayColor: AppColors.textoOscuro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondo,
        elevation: 0,
        foregroundColor: AppColors.textoOscuro,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracota,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fondoDark,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.terracota,
        secondary: AppColors.naranjaSuave,
        surface: AppColors.fondoClaroDark,
        onPrimary: Colors.white,
        onSurface: AppColors.textoOscuroDark,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textoOscuroDark,
        displayColor: AppColors.textoOscuroDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondoDark,
        elevation: 0,
        foregroundColor: AppColors.textoOscuroDark,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracota,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class Tonos {
  final Color fondo;
  final Color fondoClaro;
  final Color cremaTarjeta;
  final Color textoOscuro;
  final Color textoSuave;

  const Tonos({
    required this.fondo,
    required this.fondoClaro,
    required this.cremaTarjeta,
    required this.textoOscuro,
    required this.textoSuave,
  });

  static Tonos of(BuildContext context) {
    final esDark = Theme.of(context).brightness == Brightness.dark;
    return esDark
        ? const Tonos(
            fondo: AppColors.fondoDark,
            fondoClaro: AppColors.fondoClaroDark,
            cremaTarjeta: AppColors.cremaTarjetaDark,
            textoOscuro: AppColors.textoOscuroDark,
            textoSuave: AppColors.textoSuaveDark,
          )
        : const Tonos(
            fondo: AppColors.fondo,
            fondoClaro: AppColors.fondoClaro,
            cremaTarjeta: AppColors.cremaTarjeta,
            textoOscuro: AppColors.textoOscuro,
            textoSuave: AppColors.textoSuave,
          );
  }
}
