import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);
final ValueNotifier<String?> alertNotifier = ValueNotifier(null);
final ValueNotifier<bool> isSidebarExpanded = ValueNotifier(true);

class AppService {
  static const String _themeKey = 'isDarkMode';
  static const String _sidebarKey = 'isSidebarExpanded';

  // 1. Cargar el tema guardado al arrancar la app
  static Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark =
        prefs.getBool(_themeKey) ?? true; // Por defecto claro si no existe
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    isSidebarExpanded.value = prefs.getBool(_sidebarKey) ?? true;
  }

  static Future<void> toggleSidebar() async {
    final prefs = await SharedPreferences.getInstance();
    isSidebarExpanded.value = !isSidebarExpanded.value;
    await prefs.setBool(_sidebarKey, isSidebarExpanded.value);
  }

  static void toggleTheme() {
    themeNotifier.value =
        (themeNotifier.value == ThemeMode.light)
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static Future<void> runWithLoading(Future<void> Function() task) async {
    loadingNotifier.value = true;
    try {
      await task();
    } catch (e) {
      showAlert("Error: ${e.toString()}");
    } finally {
      loadingNotifier.value = false;
    }
  }

  static void showAlert(String message) {
    alertNotifier.value = message;
    print(message);
    Future.delayed(
      const Duration(seconds: 3),
      () => alertNotifier.value = null,
    );
  }
}
