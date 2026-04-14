import 'package:cargasuy/models/vehiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehiculoService {
  final _supabase = Supabase.instance.client;

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
