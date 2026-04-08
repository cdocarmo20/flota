import 'package:flutter/material.dart';

// --- COLORES PERSONALIZADOS ---
class AppColors {
  static const Color primary = Colors.indigo;
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E26);
}

// --- TEMA CLARO ---
final ThemeData appThemeLight = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: AppColors.primary,
  scaffoldBackgroundColor: AppColors.backgroundLight,

  // Estilo de las Tarjetas (Cards)
  cardTheme: CardTheme(
    color: AppColors.cardLight,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
    ),
  ),

  // Estilo del NavigationRail (Sidebar)
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.white,
    selectedIconTheme: IconThemeData(color: AppColors.primary),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
    selectedLabelTextStyle: TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.bold,
    ),
  ),

  // Estilo de los Botones
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
);

// --- TEMA OSCURO ---
final ThemeData appThemeDark = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: AppColors.primary,
  scaffoldBackgroundColor: AppColors.backgroundDark,

  cardTheme: CardTheme(
    color: AppColors.cardDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
    ),
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Color(0xFF1E1E26),
    selectedIconTheme: IconThemeData(color: Colors.white),
    unselectedIconTheme: IconThemeData(color: Colors.grey),
  ),
);
