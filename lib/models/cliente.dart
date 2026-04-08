class Cliente {
  final String nombre;
  final String email;
  final String status;
  final DateTime ultimaEdicion; // <--- Nuevo campo

  Cliente({
    required this.nombre,
    required this.email,
    required this.status,
    required this.ultimaEdicion,
  });
}
