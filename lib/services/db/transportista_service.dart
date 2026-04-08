import 'package:demos/models/transportista.dart';
import 'package:demos/models/vehiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransportistaService {
  final _supabase = Supabase.instance.client;

  // OBTENER TODOS LOS TRANSPORTISTAS
  Future<List<Transportista>> fetchTransportistas() async {
    try {
      // Agregamos 'vehiculos(*)' para traer todos los campos de la flota vinculada
      final response = await _supabase
          .from('transportistas')
          .select('*, localidades(nombre), vehiculos(*)');

      return (response as List).map((json) {
        return Transportista(
          id: json['id'],
          nombre: json['nombre'],
          razonSocial: json['razon_social'],
          localidadNombre: json['localidades']?['nombre'] ?? 'Sin localidad',
          // MAPEO DE VEHÍCULOS: Convertimos el JSON en objetos Vehiculo
          vehiculos:
              (json['vehiculos'] as List)
                  .map(
                    (v) => Vehiculo(
                      id: "",
                      patente: v['patente'],
                      modelo: v['modelo'],
                      capacidad: "${v['capacidad_ton']} Ton",
                      tipo: v['tipo'],
                    ),
                  )
                  .toList(),
          telefono: json['telefono'] ?? '',
          direccion: json['direccion'] ?? '',
          observaciones: json['observaciones'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar datos: $e');
    }
  }

  Future<List<String>> fetchTiposVehiculo() async {
    final response = await _supabase
        .from('tipos_vehiculo')
        .select('nombre')
        .order('nombre', ascending: true);

    return (response as List).map((item) => item['nombre'] as String).toList();
  }

  // Guardar un nuevo tipo y devolver el nombre
  Future<String> crearTipoVehiculo(String nombre) async {
    final res =
        await _supabase
            .from('tipos_vehiculo')
            .insert({'nombre': nombre})
            .select()
            .single();
    return res['nombre'];
  }

  Future<void> agregarVehiculoIndividual(
    String transportistaId,
    Vehiculo v,
  ) async {
    await _supabase.from('vehiculos').insert({
      'transportista_id': transportistaId,
      'patente': v.patente,
      'modelo': v.modelo,
      'capacidad_ton':
          double.tryParse(v.capacidad.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      'tipo': v.tipo,
    });
  }

  Future<String> guardarTransportistaCompleto(
    Transportista t,
    List<Vehiculo> flota,
  ) async {
    // 1. Insertar el transportista
    final resTransportista =
        await _supabase
            .from('transportistas')
            .insert({
              'nombre': t.nombre,
              'razon_social': t.razonSocial,
              'direccion': t.direccion,
              'telefono': t.telefono,
              'localidad_id': t.localidadId,
              'observaciones': t.observaciones,
            })
            .select()
            .single();

    final String transportistaId = resTransportista['id'];

    // 2. Insertar su flota de vehículos vinculada
    if (flota.isNotEmpty) {
      final vehiculosData =
          flota
              .map(
                (v) => {
                  'transportista_id': transportistaId,
                  'patente': v.patente,
                  'modelo': v.modelo,
                  'capacidad_ton':
                      double.tryParse(
                        v.capacidad.replaceAll(RegExp(r'[^0-9.]'), ''),
                      ) ??
                      0,
                  'tipo': v.tipo,
                },
              )
              .toList();

      await _supabase.from('vehiculos').insert(vehiculosData);
    }
    return resTransportista['id']; // Devolvemos el ID generado
  }

  // INSERTAR NUEVO TRANSPORTISTA
  Future<void> createTransportista(Map<String, dynamic> data) async {
    await _supabase.from('transportistas').insert(data);
  }

  // ELIMINAR TRANSPORTISTA
  Future<void> deleteTransportista(String id) async {
    await _supabase.from('transportistas').delete().match({'id': id});
  }

  // En lib/services/transportista_service.dart

  Future<List<Vehiculo>> fetchMisVehiculos() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) return [];

      // Buscamos en la tabla vehiculos donde el transportista_id sea el del usuario actual
      final response = await _supabase
          .from('vehiculos')
          .select('*')
          .eq('transportista_id', userId);

      return (response as List)
          .map(
            (v) => Vehiculo(
              id: v['id'], // Asegúrate de que tu modelo Vehiculo ahora tenga el campo id
              patente: v['patente'],
              modelo: v['modelo'],
              capacidad: "${v['capacidad_ton']} Ton",
              tipo: v['tipo'],
            ),
          )
          .toList();
    } catch (e) {
      print("Error al cargar mis vehículos: $e");
      return [];
    }
  }
}
