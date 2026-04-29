// class Vehiculo {
//   final String id; // <--- Agregar esto
//   final String patente;
//   final String modelo;
//   final String capacidad;
//   final String tipo;

//   Vehiculo({
//     required this.id,
//     required this.patente,
//     required this.modelo,
//     required this.capacidad,
//     required this.tipo,
//   });
// }

class Vehiculo {
  final String id;
  final String patente;
  final String modelo;
  final String capacidad;
  final String tipo;
  final String? anio; // <--- Nuevo
  final String? marcaId; // <--- Nuevo
  final String? marcaNombre; // Para mostrar el nombre sin hacer otro fetch
  final String? dueno;
  final String? tipoId;

  Vehiculo({
    required this.id,
    required this.patente,
    required this.modelo,
    required this.capacidad,
    required this.tipo,
    this.anio,
    this.marcaId,
    this.marcaNombre,
    this.dueno,
    this.tipoId,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] ?? '',
      patente: json['patente'] ?? '',
      modelo: json['modelo'] ?? '',
      capacidad: json['capacidad_ton']?.toString() ?? '',
      tipoId: json['tipo_id'],
      tipo:
          json['tipo_vehiculo'] != null ? json['tipo_vehiculo']['nombre'] : '',
      anio: json['anio'],
      marcaId: json['marca_id'],
      // Si en la consulta de Supabase usaste .select('*, marcas_vehiculos(nombre)')
      marcaNombre:
          json['marcas_vehiculos'] != null
              ? json['marcas_vehiculos']['nombre']
              : '',

      dueno:
          json['transportistas'] != null
              ? json['transportistas']['nombre']
              : '',
    );
  }
}
