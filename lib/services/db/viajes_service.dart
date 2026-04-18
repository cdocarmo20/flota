import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViajesService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> obtenerBannerInfo(String userId) async {
    try {
      // 1. Obtener la localidad del usuario (esto ya lo tenías)
      final userProfile =
          await Supabase.instance.client
              .from('clientes')
              .select('localidad_id, localidades(nombre)')
              .eq('id', userId)
              .single();

      final localidadId = userProfile['localidad_id'];
      final nombreLocalidad = userProfile['localidades']['nombre'];

      // 2. CONTAR VIAJES (Sintaxis corregida)
      final res = await Supabase.instance.client
          .from('viajes')
          .select('id') // Solo seleccionamos el ID
          .eq('estado', 'PENDIENTE')
          .eq('origen_id', localidadId)
          .limit(1) // No necesitamos los registros
          .count(CountOption.exact); // Pedimos el conteo exacto
      // En las versiones nuevas, el conteo viene en la propiedad 'count'
      final int cantidad = res.count ?? 0;

      return {'localidad': nombreLocalidad, 'cantidad': cantidad};
    } catch (e) {
      print("Error en Banner: $e");
      return {'localidad': 'Uruguay', 'cantidad': 0};
    }
  }

  Future<Map<String, int>> obtenerEstadisticasDashboard(String userId) async {
    try {
      // Consultamos todos los viajes donde el usuario participa (como creador o transportista)
      final response = await Supabase.instance.client
          .from('viajes')
          .select('estado')
          .or('creador_id.eq.$userId,transportista_id.eq.$userId');

      final List viajes = response as List;

      return {
        'pendientes': viajes.where((v) => v['estado'] == 'PENDIENTE').length,
        'aceptados': viajes.where((v) => v['estado'] == 'ACEPTADO').length,
        'finalizados': viajes.where((v) => v['estado'] == 'CONFIRMADO').length,
        'total': viajes.length,
      };
    } catch (e) {
      print('Error en stats: $e');
      return {'pendientes': 0, 'aceptados': 0, 'finalizados': 0, 'total': 0};
    }
  }

  Future<void> procesarFinalizacionViaje({
    required String viajeId,
    required String creadorId,
    required String nombreTransportista,
  }) async {
    try {
      // 1. Actualizamos el estado del viaje
      await Supabase.instance.client
          .from('viajes')
          .update({'estado': 'FINALIZADO'})
          .eq('id', viajeId);

      // 2. Insertamos la notificación para el creador
      await Supabase.instance.client.from('notificaciones').insert({
        'usuario_id': creadorId,
        'viaje_id': viajeId,
        'mensaje': '🏁 ¡Tu carga ha sido entregada por $nombreTransportista!',
      });
    } catch (e) {
      print('Error en procesarFinalizacionViaje: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleViaje(String viajeId) async {
    try {
      // Usamos la misma lógica de relaciones explícitas que nos funcionó antes
      final data =
          await Supabase.instance.client
              .from('viajes')
              .select('''
          *,
          creador:clientes!creador_id(nombre, telefono),
          origen:origen_id(nombre, latitud, longitud),
          destino:destino_id(nombre, latitud, longitud),
          transportista:transportista_id(nombre, telefono),
          vehiculo:vehiculo_id(patente, modelo)
          resenias:valoraciones!viaje_id(estrellas, comentario, created_at)
          ''')
              .eq('id', viajeId)
              .maybeSingle();
      return data ?? {};
    } catch (e) {
      print('Error en obtenerDetalleViaje: $e');
      rethrow;
    }
  }

  Future<void> crearViaje(Map<String, dynamic> datos) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('viajes').insert({
      'creador_id': userId, // Puede ser un cliente o un transportista
      'origen_id': datos['origen_id'],
      'destino_id': datos['destino_id'],
      'origen_direccion': datos['origen_direccion'],
      'origen_lat': datos['origen_lat'],
      'origen_lng': datos['origen_lng'],
      'destino_direccion': datos['destino_direccion'],
      'destino_lat': datos['destino_lat'],
      'destino_lng': datos['destino_lng'],
      'descripcion_carga': datos['descripcion'],
      'peso_estimado': datos['peso'],
      'precio_ofertado': datos['precio'],
      'fecha_viaje': datos['fecha_viaje'],
      'estado': 'PENDIENTE',
    });
  }

  Future<void> eliminarViaje(String viajeId) async {
    try {
      print('object');
      await Supabase.instance.client.from('viajes').delete().eq('id', viajeId);
    } catch (e) {
      print(e);
      throw Exception('Error al eliminar el viaje: $e');
    }
  }

  Future<void> cancelarViaje(String viajeId) async {
    try {
      await Supabase.instance.client
          .from('viajes')
          .update({'estado': 'CANCELADO'}) // Cambiamos el estado
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al cancelar el viaje: $e');
    }
  }

  Future<void> actualizarViaje({
    required String viajeId,
    required String descripcion,
    required double peso,
    required double precio,
    required String origenId,
    required String destinoId,
    required DateTime? fechaViaje,
  }) async {
    try {
      await Supabase.instance.client
          .from('viajes')
          .update({
            'descripcion_carga': descripcion,
            'peso_estimado': peso,
            'precio_ofertado': precio,
            'origen_id': origenId, // UUID
            'destino_id': destinoId, // UUID
            'fecha_viaje':
                fechaViaje?.toIso8601String().split(
                  'T',
                )[0], // Solo la fecha YYYY-MM-DD
          })
          .eq('id', viajeId);
    } catch (e) {
      throw Exception('Error al actualizar: $e');
    }
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

  Future<List<Map<String, dynamic>>> obtenerMisViajesTransportista(
    String userId,
  ) async {
    final data = await Supabase.instance.client
        .from('viajes')
        .select('*, origen:origen_id(nombre), destino:destino_id(nombre)')
        .eq('transportista_id', userId)
        .filter('estado', 'in', '("CONFIRMADO","FINALIZADO","ACEPTADO")')
        .order('fecha_viaje', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> obtenerMisViajesAceptados() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      return await Supabase.instance.client
          .from('viajes')
          .select('''
        *,
        origen:localidades!origen_id(nombre),
        destino:localidades!destino_id(nombre),
        creador:clientes!creador_id(nombre, telefono),
        vehiculo:vehiculos!vehiculo_id(patente, modelo)
      ''')
          .eq('transportista_id', userId)
          .eq('estado', 'ACEPTADO')
          .order('fecha_viaje', ascending: true);

      // transportista:clientes!transportista_id(nombre) estono se si va
    } catch (e) {
      print("❌ Error real capturado: $e");
      return [];
    }
  }

  Future<void> marcarNotificacionLeida(int notificacionId) async {
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', notificacionId);
    } catch (e) {
      print("Error al marcar como leída: $e");
    }
  }

  Future<void> marcarComoLeida(dynamic id) async {
    await Supabase.instance.client
        .from('notificaciones')
        .update({'leida': true})
        .eq('id', id);
  }

  Future<void> enviarResenia({
    required String viajeId,
    required String receptorId,
    required String emisorId,
    required int estrellas,
    required String comentario,
  }) async {
    // 1. Insertar la reseña
    await Supabase.instance.client.from('resenias').insert({
      'viaje_id': viajeId,
      'emisor_id': emisorId,
      'receptor_id': receptorId,
      'estrellas': estrellas,
      'comentario': comentario,
    });

    // 2. Notificar al transportista
    await Supabase.instance.client.from('notificaciones').insert({
      'usuario_id': receptorId,
      'viaje_id': viajeId,
      'mensaje':
          '⭐ ¡Has recibido una calificación de $estrellas estrellas por tu último viaje!',
    });
  }

  Future<void> cambiarEstadoViaje(String viajeId, String nuevoEstado) async {
    await Supabase.instance.client
        .from('viajes')
        .update({'estado': nuevoEstado})
        .eq('id', viajeId);

    // Aquí podrías disparar notificaciones automáticas:
    // Si pasa a FINALIZADO -> Notificar al Cliente.
    // Si pasa a CONFIRMADO -> Notificar al Transportista (¡Ya podés cobrar!).
  }

  Future<void> finalizarViaje(
    String viajeId,
    String clienteId,
    String origenNombre,
    String destinoNombre,
  ) async {
    try {
      await Supabase.instance.client
          .from('viajes')
          .update({'estado': 'FINALIZADO'})
          .eq('id', viajeId);

      // // Opcional: Insertar en una tabla de 'notificaciones' para que el cliente la vea después
      // await Supabase.instance.client.from('notificaciones').insert({
      //   'usuario_id': clienteId,
      //   'mensaje': '¡Tu carga ha llegado a destino! 🏁',
      //   'leida': false,
      // });

      await Supabase.instance.client.from('notificaciones').insert({
        'usuario_id': clienteId,
        'viaje_id':
            viajeId, // Guardamos la referencia por si quiere hacer click e ir al viaje
        'mensaje': '🏁 Carga Entregada: $origenNombre ➔ $destinoNombre',
        'leida': false,
      });
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerMisCargasActivas2() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return await Supabase.instance.client
        .from('viajes')
        .select(
          '*, origen:localidades!origen_id(nombre), destino:localidades!destino_id(nombre)',
        )
        .eq('creador_id', userId)
        .neq('estado', 'CANCELADO') // Excluimos los cancelados
        .order('fecha_solicitud', ascending: false);
  }

  Future<List<Map<String, dynamic>>> obtenerMisCargasActivas() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      return await Supabase.instance.client
          .from('viajes')
          .select('''
      *,
      origen:localidades!origen_id(nombre),
      destino:localidades!destino_id(nombre),
      transportista:transportista_id(nombre, telefono),
      vehiculo:vehiculo_id( modelo, patente)
    ''') // Quitamos el !clientes y !vehiculos para que use el nombre de la FK directamente
          .eq('creador_id', userId)
          .neq('estado', 'CANCELADO')
          .neq('estado', 'CONFIRMADO')
          .order('fecha_solicitud', ascending: false);
    } catch (e) {
      print("❌ Error real capturado: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialCargas() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return await Supabase.instance.client
        .from('viajes')
        .select('''
          *,
          origen:origen_id(nombre),
          destino:destino_id(nombre),
          transportista:transportista_id(nombre, telefono),
          vehiculo:vehiculo_id( modelo, patente)
        ''')
        .filter('estado', 'in', '("CONFIRMADO","CANCELADO")')
        .or('creador_id.eq.$userId')
        .order('fecha_solicitud', ascending: false);
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

  Future<void> aceptarYAsignarViaje(
    String viajeId,
    String vehiculoId,
    String creadorId,
  ) async {
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

      await Supabase.instance.client.from('notificaciones').insert({
        'usuario_id': creadorId,
        'mensaje':
            '✅ ¡Un transportista ha aceptado tu carga! Ya puedes ver los detalles.',
        'leida': false,
        'viaje_id': viajeId,
      });

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
