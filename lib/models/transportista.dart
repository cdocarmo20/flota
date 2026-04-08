import 'package:demos/models/vehiculo.dart';

class Transportista {
  final String id;
  final String nombre;
  final String razonSocial;
  final String direccion;
  final String telefono;
  final String? localidadId;
  final String? localidadNombre;
  final String observaciones;
  // Agrega este campo si no lo tienes para manejar la relación local
  final List<Vehiculo> vehiculos;

  Transportista({
    required this.id,
    required this.nombre,
    required this.razonSocial,
    required this.direccion,
    required this.telefono,
    this.localidadId,
    this.localidadNombre,
    this.observaciones = '',
    this.vehiculos = const [], // Valor por defecto lista vacía
  });
}
