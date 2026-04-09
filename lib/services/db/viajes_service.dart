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
      'fecha_viaje': datos['fecha_viaje'],
      'estado': 'PENDIENTE',
    });
  }

  Future<List<Map<String, dynamic>>> obtenerMisCargasSolicitadas() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return await Supabase.instance.client
        .from('viajes')
        .select('''
        *,
        origen:localidades!origen_id(nombre),
        destino:localidades!destino_id(nombre),
        transportista:transportista_id(nombre, telefono)
        ''')
        .eq('creador_id', userId)
        .order('fecha_viaje', ascending: false); // Usamos tu campo real
  }

  Future<List<Map<String, dynamic>>> fetchCargasCercanas({
    required double? lat,
    required double? lon,
    required double radio,
    bool buscarEnDestino = false,
    DateTime? fechaInicio, // Si viene null, no filtra
    DateTime? fechaFin,
  }) async {
    try {
      final Map<String, dynamic> parametros = {
        'lat_ref': lat,
        'lon_ref': lon,
        'radio_km': radio,
        'por_destino': buscarEnDestino,
        'fecha_inicio': fechaInicio?.toIso8601String(),
        'fecha_fin': fechaFin?.toIso8601String(), // Enviará null si es null
      };

      final List<dynamic> response = await _supabase.rpc(
        'buscar_viajes_cercanos',
        params: parametros,
      );

      // Llamada a la función RPC

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Si falla la búsqueda geográfica, intentamos una carga normal por seguridad
      final fallback = await _supabase
          .from('viajes')
          .select(
            '*, origen:localidades!origen_id(nombre), destino:localidades!destino_id(nombre), creador:clientes!creador_id(nombre, mail, celular)',
          )
          .eq('estado', 'PENDIENTE');
      return List<Map<String, dynamic>>.from(fallback);
    }
  }

  // Future<List<Map<String, dynamic>>> fetchCargasCercanas({
  //   double? lat,
  //   double? lon,
  //   double? radio,
  //   String? destinoId,
  // }) async {
  //   print(lat.toString());
  //   // CASO A: Si el usuario eligió un Origen y quiere ver a la redonda (80km)
  //   if (lat != null && lon != null && radio != null) {
  //     final List<dynamic> response = await _supabase.rpc(
  //       'buscar_viajes_cercanos',
  //       params: {'lat_origen': lat, 'lon_origen': lon, 'radio_km': radio},
  //     );
  //     return List<Map<String, dynamic>>.from(response);
  //   }

  //   // CASO B: Búsqueda normal sin radio (todos los viajes o solo por destino)
  //   var query = _supabase
  //       .from('viajes')
  //       .select('*, ...')
  //       .eq('estado', 'PENDIENTE');
  //   if (destinoId != null) query = query.eq('destino_id', destinoId);

  //   final res = await query.order('fecha_solicitud');
  //   return List<Map<String, dynamic>>.from(res);
  // }

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
    try {
      await _supabase
          .from('viajes')
          .update({
            'transportista_id': transportistaId,
            'vehiculo_id': vehiculoId,
            'estado': 'ACEPTADO',
            'fecha_aceptacion': DateTime.now().toIso8601String(),
          })
          .eq('id', viajeId.toString());

      // if (response.isEmpty) {
      //   print("⚠️ No se encontró el viaje o RLS bloqueó la edición.");
      // } else {
      //   print("✅ Viaje actualizado: ${response[0]}");
      // }
    } catch (e) {
      print("❌ Error real capturado: $e");
    }
  }

  // Future<List<Map<String, dynamic>>> fetchMisViajes() async {
  //   final userId = _supabase.auth.currentUser?.id;

  //   final response = await _supabase
  //       .from('viajes')
  //       .select('''
  //         *,
  //         origen:localidades!origen_id(nombre),
  //         destino:localidades!destino_id(nombre),
  //         transportista:transportistas(nombre, telefono)
  //       ''')
  //       .eq('cliente_id', userId as Object)
  //       .order('fecha_solicitud', ascending: false);

  //   return response as List<Map<String, dynamic>>;
  // }

  Future<void> cancelarViaje(String viajeId) async {
    await _supabase.from('viajes').delete().match({'id': viajeId});
  }

  // Future<void> aceptarViaje(String viajeId, String transportistaId) async {
  //   await Supabase.instance.client
  //       .from('viajes')
  //       .update({'transportista_id': transportistaId, 'estado': 'ACEPTADO'})
  //       .match({'id': viajeId});

  //   AppService.showAlert("Viaje asignado correctamente");
  // }

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
    final transportistaId = Supabase.instance.client.auth.currentUser?.id; //
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
