import 'package:demos/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
final ValueNotifier<bool> isSidebarExpanded = ValueNotifier(true);
final ValueNotifier<UserRole?> userRole = ValueNotifier(null);
final ValueNotifier<Map<String, dynamic>?> userLocalidad = ValueNotifier(null);
final ValueNotifier<String?> userStatus = ValueNotifier(null);

class AuthService {
  static const String _authKey = 'isLoggedIn';
  static const String _rememberKey = 'rememberMe';

  static Future<void> checkLoginStatus() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        // Hacemos un Join con localidades para obtener el nombre y el ID
        final data =
            await Supabase.instance.client
                .from('clientes')
                .select('rol, localidad_id, localidades(nombre), estado')
                .eq('id', user.id)
                .single();
        userStatus.value = data['estado'] ?? 'PENDIENTE';
        // Guardamos el rol
        final String rolDB = data['rol'] ?? 'cliente';
        userRole.value = UserRole.values.firstWhere((e) => e.name == rolDB);

        // Guardamos la localidad para usarla en los formularios
        if (data['localidad_id'] != null) {
          userLocalidad.value = {
            'id': data['localidad_id'],
            'nombre': data['localidades']['nombre'],
          };
        }

        isAuthenticated.value = true;
      } catch (e) {
        print("Error cargando datos del cliente: $e");
      }
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      // 1. Intentar el login en Supabase Auth
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      if (res.user != null) {
        // 2. Si el login es exitoso, cargamos el Rol y Localidad
        await checkLoginStatus();
        return true;
      }
      return false;
    } catch (e) {
      // Captura errores como "Invalid login credentials"
      print("Error de login: $e");
      return false;
    }
  }

  // Cerrar Sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
    isAuthenticated.value = false;
  }
}
