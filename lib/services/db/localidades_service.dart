import 'package:supabase_flutter/supabase_flutter.dart';

class LocalidadService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchLocalidades() async {
    final response = await Supabase.instance.client
        .from('localidades')
        .select('id, nombre, latitud, longitud')
        .order('nombre', ascending: true);
    // return response as List<Map<String, dynamic>>;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> crearLocalidad(
    String nombre,
    double lat,
    double long,
  ) async {
    final res =
        await _supabase
            .from('localidades')
            .insert({'nombre': nombre, 'latitud': lat, 'longitud': long})
            .select()
            .single();
    return res;
  }

  Future<String> obtenerIdLocalidad(String nombre) async {
    final data =
        await _supabase
            .from('localidades') // Ajusta el nombre de tu tabla
            .select('id')
            .eq('nombre', nombre)
            .single();

    return data['id'].toString();
  }
}
