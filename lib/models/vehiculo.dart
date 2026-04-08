class Vehiculo {
  final String id; // <--- Agregar esto
  final String patente;
  final String modelo;
  final String capacidad;
  final String tipo;

  Vehiculo({
    required this.id,
    required this.patente,
    required this.modelo,
    required this.capacidad,
    required this.tipo,
  });
}
