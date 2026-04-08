import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  static const String _authKey = 'isLoggedIn';
  static const String _rememberKey = 'rememberMe';

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    notifyListeners();
  }

  static Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberKey) ?? false;

    // Si no marcó "recuérdame", en una web real la sesión expiraría.
    // Aquí simulamos que si rememberMe es false, evaluamos si debe seguir logueado.
    isAuthenticated.value = prefs.getBool(_authKey) ?? false;
  }

  Future<void> login(String user, String pass) async {
    // Simulación de validación
    if (user == "admin" && pass == "1234") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _isLoggedIn = false;
    notifyListeners();
  }
}

class AuthService {
  static const String _authKey = 'isLoggedIn';
  static const String _rememberKey = 'rememberMe';

  static Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberKey) ?? false;

    // Si no marcó "recuérdame", en una web real la sesión expiraría.
    // Aquí simulamos que si rememberMe es false, evaluamos si debe seguir logueado.
    isAuthenticated.value = prefs.getBool(_authKey) ?? false;
  }

  static Future<bool> login(
    String user,
    String password,
    bool rememberMe,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    if (user == "admin" && password == "1234") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authKey, true);
      await prefs.setBool(_rememberKey, rememberMe); // Guardamos la preferencia
      isAuthenticated.value = true;
      return true;
    }
    return false;
  }
}
