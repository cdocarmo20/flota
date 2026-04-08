class Viaje {
  final String id;
  final String origen;
  final String destino;
  final String descripcion;
  final double peso;
  final String estado;
  final String? transportistaNombre;

  Viaje({
    required this.id,
    required this.origen,
    required this.destino,
    required this.descripcion,
    required this.peso,
    required this.estado,
    this.transportistaNombre,
  });
}
