import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  final _supabase = Supabase.instance.client;

  // Actualizar los datos del perfil del cliente
  Future<void> actualizarPerfil({
    required String nombre,
    required String telefono,
    required String direccion,
    required String? localidadId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('clientes')
        .update({
          'nombre': nombre,
          'telefono': telefono,
          'direccion': direccion,
          'localidad_id': localidadId,
        })
        .eq('id', userId as Object);
  }

  Future<void> adminActualizarPassword(
    String targetId,
    String nuevaPass,
  ) async {
    try {
      // Llamamos a la función SQL que creamos arriba
      await _supabase.rpc(
        'admin_change_password',
        params: {'target_user_id': targetId, 'new_password': nuevaPass},
      );
    } catch (e) {
      throw Exception("Error de servidor: $e");
    }
  }

  // 1. EDITAR DATOS GENERALES
  Future<void> actualizarDatosPerfil({
    required String userId,
    required Map<String, dynamic> nuevosDatos,
  }) async {
    await _supabase.from('clientes').update(nuevosDatos).eq('id', userId);
  }

  // 2. CAMBIAR CONTRASEÑA
  // Nota: Supabase permite que el usuario logueado cambie su propia pass
  Future<void> actualizarContrasena(String nuevaPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: nuevaPassword));
  }
}
