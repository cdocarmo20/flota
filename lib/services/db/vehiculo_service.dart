import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/models/vehiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehiculoService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> obtenerMarcas() async {
    final data = await Supabase.instance.client
        .from('marcas_vehiculos')
        .select('id, nombre')
        .order('nombre');
    return List<Map<String, dynamic>>.from(data);
  }

  // Crear una nueva marca y retornar el objeto creado
  Future<Map<String, dynamic>> crearMarca(String nombre) async {
    final data =
        await Supabase.instance.client
            .from('marcas_vehiculos')
            .insert({'nombre': nombre})
            .select()
            .single();
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchFlotaCompleta() async {
    try {
      // Importante: 'transportistas' es el nombre de la TABLA vinculada en el SQL
      final response = await _supabase
          .from('vehiculos')
          .select('*, transportistas(nombre, telefono)');

      if (response == null) return [];

      return (response as List).map((json) {
        return {
          'vehiculo': Vehiculo(
            id: json['id'],
            patente: json['patente'] ?? 'S/P',
            modelo: json['modelo'] ?? 'S/M',
            capacidad: "${json['capacidad_ton'] ?? 0} Ton",
            tipo: json['tipo'] ?? 'General',
          ),
          // Accedemos al objeto anidado creado por el JOIN
          'dueno': json['transportistas']?['nombre'] ?? 'Sin dueño',
          'contacto': json['transportistas']?['telefono'] ?? 'Sin contacto',
        };
      }).toList();
    } catch (e) {
      print("ERROR EN FETCH FLOTA: $e");
      return [];
    }
  }

  Future<void> guardarVehiculo({
    String? id,
    required String patente,
    required String modelo,
    required String capacidad,
    required String tipo,
    required int anio,
    required String marcaId,
    required String userID,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final datos = {
      'patente': patente,
      'modelo': modelo,
      'capacidad_ton': capacidad,
      'tipo': tipo,
      'anio': anio,
      'marca_id': marcaId,
      'transportista_id': userID, // ID del dueño
    };

    if (id == null) {
      // NUEVO VEHÍCULO
      await Supabase.instance.client.from('vehiculos').insert(datos);
    } else {
      // EDITAR EXISTENTE
      await Supabase.instance.client
          .from('vehiculos')
          .update(datos)
          .eq('id', id);
    }
  }

  Future<void> actualizarVehiculo(
    String id,
    String patente,
    String modelo,
    String capacidad,
    String tipo,
  ) async {
    try {
      await Supabase.instance.client
          .from('vehiculos')
          .update({
            'patente': patente,
            'modelo': modelo,
            'capacidad_ton': capacidad,
            'tipo': tipo,
          })
          .eq('id', id); // Filtramos por el UUID
    } catch (e) {
      print("Error al actualizar vehiculo: $e");
    }
  }

  Future<List<Map<String, dynamic>>> obtenerVehiculos(
    UserRole rol,
    String userId,
  ) async {
    var query = Supabase.instance.client
        .from('vehiculos')
        .select('*, transportistas(nombre), marcas_vehiculos(nombre)');

    if (rol == UserRole.transportista) {
      query = query.eq('transportista_id', userId);
    }
    final data = await query.order('patente', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchFlotaCompleta2() async {
    try {
      // Traemos el vehículo y los datos básicos del transportista dueño
      final response = await _supabase
          .from('vehiculos')
          .select('*, transportistas(nombre, telefono)');

      return (response as List).map((json) {
        return {
          'vehiculo': Vehiculo(
            id: json['id'],
            patente: json['patente'],
            modelo: json['modelo'],
            capacidad: "${json['capacidad_ton']} Ton",
            tipo: json['tipo'],
          ),
          'dueno': json['transportistas']['nombre'],
          'contacto': json['transportistas']['telefono'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar la flota: $e');
    }
  }
}
