import 'package:demos/models/usuario.dart';
import 'package:demos/services/app_state.dart';
import 'package:demos/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViajesService {
  final _supabase = Supabase.instance.client;

  Future<void> crearViaje(Map<String, dynamic> datos) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('viajes').insert({
      'creador_id': userId, // Puede ser un cliente o un transportista
      'origen_id': datos['origen_id'],
      'destino_id': datos['destino_id'],
      'descripcion_carga': datos['descripcion'],
      'peso_estimado': datos['peso'],
      'precio_ofertado': datos['precio'],
      'estado': 'PENDIENTE',
    });
  }

  // Future<void> crearViaje(Map<String, dynamic> datos) async {
  //   try {
  //     // 1. Obtener el ID del usuario logueado actualmente
  //     final userId = _supabase.auth.currentUser?.id;

  //     if (userId == null) throw Exception("Usuario no autenticado");

  //     // 2. Insertar con el ID del cliente
  //     await _supabase.from('viajes').insert({
  //       'cliente_id': userId, // Este campo es obligatorio en la DB
  //       'origen_id': datos['origen_id'],
  //       'destino_id': datos['destino_id'],
  //       'descripcion_carga': datos['descripcion'],
  //       'peso_estimado': datos['peso'],
  //       'precio_ofertado': datos['precio'],
  //       'estado': 'PENDIENTE',
  //     });
  //   } catch (e) {
  //     print("Error detallado en Supabase: $e");
  //     throw Exception("No se pudo guardar el viaje: $e");
  //   }
  // }

  // En lib/services/viajes_service.dart

  Future<List<Map<String, dynamic>>> fetchCargasFiltradas({
    String? origenId,
    String? destinoId,
    double? pesoMaximo,
  }) async {
    try {
      var query = _supabase
          .from('viajes')
          .select('''
          *,
          origen:localidades!origen_id(nombre),
          destino:localidades!destino_id(nombre),
          creador:clientes!creador_id(nombre, mail, celular) 
        ''') // <--- CAMBIO AQUÍ: Usamos creador_id
          .eq('estado', 'PENDIENTE');

      // ... resto de tus filtros (eq origen, eq destino, lte peso)

      final response = await query.order('fecha_solicitud', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error en fetchCargasFiltradas: $e");
      return [];
    }
  }

  Future<void> aceptarYAsignarViaje(String viajeId, String vehiculoId) async {
    final transportistaId = _supabase.auth.currentUser!.id;

    await _supabase
        .from('viajes')
        .update({
          'transportista_id': transportistaId,
          'vehiculo_id': vehiculoId,
          'estado': 'ACEPTADO',
        })
        .match({'id': viajeId});
  }

  Future<List<Map<String, dynamic>>> fetchMisViajes() async {
    final userId = _supabase.auth.currentUser?.id;

    final response = await _supabase
        .from('viajes')
        .select('''
          *,
          origen:localidades!origen_id(nombre),
          destino:localidades!destino_id(nombre),
          transportista:transportistas(nombre, telefono)
        ''')
        .eq('cliente_id', userId as Object)
        .order('fecha_solicitud', ascending: false);

    return response as List<Map<String, dynamic>>;
  }

  Future<void> cancelarViaje(String viajeId) async {
    await _supabase.from('viajes').delete().match({'id': viajeId});
  }

  Future<void> aceptarViaje(String viajeId, String transportistaId) async {
    await Supabase.instance.client
        .from('viajes')
        .update({'transportista_id': transportistaId, 'estado': 'ACEPTADO'})
        .match({'id': viajeId});

    AppService.showAlert("Viaje asignado correctamente");
  }

  // En lib/services/viajes_service.dart

  Future<List<Map<String, dynamic>>> fetchCargasDisponibles(
    String? localidadId,
  ) async {
    // Traemos viajes pendientes con sus localidades
    var query = _supabase
        .from('viajes')
        .select('''
        *,
        origen:localidades!origen_id(id, nombre),
        destino:localidades!destino_id(nombre)
      ''')
        .eq('estado', 'PENDIENTE');

    final response = await query.order('fecha_solicitud', ascending: false);
    List<Map<String, dynamic>> lista = List<Map<String, dynamic>>.from(
      response,
    );

    // Si el transportista tiene localidad, ponemos esos viajes al principio de la lista
    if (localidadId != null) {
      lista.sort((a, b) {
        if (a['origen']['id'] == localidadId) return -1;
        if (b['origen']['id'] == localidadId) return 1;
        return 0;
      });
    }

    return lista;
  }

  Future<void> asignarViajeAVehiculo(String viajeId, String vehiculoId) async {
    final transportistaId =
        Supabase
            .instance
            .client
            .auth
            .currentUser
            ?.id; // ID del transportista logueado

    await Supabase.instance.client
        .from('viajes')
        .update({
          'transportista_id': transportistaId,
          'vehiculo_id': vehiculoId,
          'estado': 'ACEPTADO',
        })
        .match({'id': viajeId});
  }

  Future<void> actualizarEstadoViaje(String viajeId, String nuevoEstado) async {
    await _supabase.from('viajes').update({'estado': nuevoEstado}).match({
      'id': viajeId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchViajesSegunRol() async {
    final user = Supabase.instance.client.auth.currentUser;
    final rol = userRole.value; // El notificador que ya creamos

    var query = Supabase.instance.client
        .from('viajes')
        .select(
          '*, origen:localidades!origen_id(id, nombre), destino:localidades!destino_id(nombre)',
          // .select(
          //   '*, origen:localidades!origen_id(nombre), destino:localidades!destino_id(nombre)',
        );

    if (rol == UserRole.admin) {
      // Admin: No aplicamos filtros extra, la RLS permite todo
    } else if (rol == UserRole.cliente) {
      // Cliente: Filtramos por su ID
      query = query.eq('cliente_id', user!.id);
    } else if (rol == UserRole.transportista) {
      // Transportista: Combinamos lógica (Pendientes o Propios)
      // Usamos el filtro 'or' de Supabase
      query = query.or('estado.eq.PENDIENTE,transportista_id.eq.${user!.id}');
    }

    final response = await query.order('fecha_solicitud', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
