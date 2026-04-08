enum UserRole { cliente, transportista, admin }

class Usuario {
  final String id;
  final UserRole rol;

  Usuario({required this.id, required this.rol});
}
