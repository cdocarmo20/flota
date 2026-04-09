import 'package:supabase_flutter/supabase_flutter.dart';

class LocalidadService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchLocalidades() async {
    final response = await Supabase.instance.client
        .from('localidades')
        .select('id, nombre, latitud, longitud')
        .order('nombre', ascending: true);
    return response as List<Map<String, dynamic>>;
  }

  Future<Map<String, dynamic>> crearLocalidad(String nombre) async {
    final res =
        await _supabase
            .from('localidades')
            .insert({'nombre': nombre})
            .select()
            .single();
    return res;
  }
}
