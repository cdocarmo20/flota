import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/services/db/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/page_layout.dart';
import '../services/app_state.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> usuariosEnLinea = [];

  // void escucharUsuariosActivos() {
  //     // Asegúrate de que el canal esté inicializado pero NO suscrito aún
  //     AppService.presenceChannel!.on(
  //       RealtimeListenTypes.presence,
  //       ChannelFilter(event: 'sync'), // 'sync' es el evento para presencia
  //       (payload, [ref]) {
  //         // Obtenemos el estado actual
  //         final state = AppService.presenceChannel!.presenceState();

  //         // Convertimos a lista legible
  //         final usuariosOnline =
  //             state.values
  //                 .expand((presence) => presence)
  //                 .map((presence) => presence.payload as Map<String, dynamic>)
  //                 .toList();

  //         print('Usuarios conectados actualmente: ${usuariosOnline.length}');
  //         // Aquí puedes actualizar un ValueNotifier o llamar a un setState
  //       },
  //     ).subscribe(); // EL SUBSCRIBE SIEMPRE AL FINAL
  //   }

  //   Widget _indicadorOnline(String userId) {
  //     // Verificamos si el ID está en nuestra lista de usuariosEnLinea
  //     bool estaActivo = usuariosEnLinea.any((u) => u['usuario_id'] == userId);

  //     return CircleAvatar(
  //       radius: 6,
  //       backgroundColor: estaActivo ? Colors.green : Colors.grey,
  //     );
  //   }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- 1. FUNCIÓN PARA CAMBIAR EL ESTADO (Aprobar/Rechazar) ---
  Future<void> _cambiarEstado(
    Map<String, dynamic> usuario,
    String nuevoEstado,
  ) async {
    AppService.runWithLoading(() async {
      try {
        await _supabase
            .from('clientes')
            .update({'estado': nuevoEstado})
            .eq('id', usuario['id']);
        setState(() {}); // Refresca la lista
        AppService.showAlert(
          "Usuario ${usuario['nombre']} ahora está $nuevoEstado",
        );
      } catch (e) {
        AppService.showAlert("Error al actualizar estado");
      }
    });
  }

  // --- 2. FUNCIÓN PARA CAMBIAR EL ROL (Cliente/Transportista/Admin) ---
  Future<void> _actualizarRol(String userId, String nuevoRol) async {
    AppService.runWithLoading(() async {
      try {
        await _supabase
            .from('clientes')
            .update({'rol': nuevoRol})
            .eq('id', userId);
        setState(() {}); // Refresca la lista
        AppService.showAlert("Rol actualizado a $nuevoRol");
      } catch (e) {
        AppService.showAlert("Error al cambiar el rol");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Gestión de Usuarios",
      icon: Icons.admin_panel_settings,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Activos", icon: Icon(Icons.check_circle)),
              Tab(text: "Pendientes", icon: Icon(Icons.hourglass_top)),
              Tab(text: "Rechazados", icon: Icon(Icons.block)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(estado: 'ACTIVO'),
                _buildUserList(estado: 'PENDIENTE'),
                _buildUserList(estado: 'RECHAZADO'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. CONSTRUCTOR DE LA LISTA ---
  Widget _buildUserList({required String estado}) {
    // bool estaActivo = usuariosEnLinea.any((u) => u['usuario_id'] == userId);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase
          .from('clientes')
          .select('*, localidades(nombre)')
          .eq('estado', estado),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final usuarios = snapshot.data!;

        return ListView.builder(
          itemCount: usuarios.length,
          itemBuilder: (context, i) {
            final u = usuarios[i];

            // Color de ícono según el estado
            Color iconColor = Colors.amber;
            if (estado == 'ACTIVO') iconColor = Colors.green;
            if (estado == 'RECHAZADO') iconColor = Colors.red;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: iconColor),
                ),
                title: Text(
                  u['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${u['mail']} • ${u['localidades']?['nombre'] ?? 'S/L'}",
                    ),
                    Text(
                      "RUT: ${u['rut'] ?? 'N/A'} • Cel: ${u['celular'] ?? 'N/A'}",
                    ), // Mostrar RUT y Celular
                    Text(
                      "Dir: ${u['direccion'] ?? 'N/A'}",
                    ), // Mostrar Dirección
                    const SizedBox(height: 4),
                    _roleBadge(u['rol']),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Si está RECHAZADO o PENDIENTE, mostramos botón para ACTIVAR
                    if (estado != 'ACTIVO')
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip: "Aprobar Usuario",
                        onPressed: () => _cambiarEstado(u, 'ACTIVO'),
                      ),

                    // Si está PENDIENTE o ACTIVO, mostramos botón para RECHAZAR
                    if (estado != 'RECHAZADO')
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: "Rechazar Usuario",
                        onPressed: () => _cambiarEstado(u, 'RECHAZADO'),
                      ),

                    // Menú de cambio de rol (Siempre disponible para el Admin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.manage_accounts),
                      onSelected:
                          (String nuevoRol) =>
                              _actualizarRol(u['id'], nuevoRol),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'cliente',
                              child: Text("Hacer Cliente"),
                            ),
                            const PopupMenuItem(
                              value: 'transportista',
                              child: Text("Hacer Transportista"),
                            ),
                            const PopupMenuItem(
                              value: 'admin',
                              child: Text("Hacer Administrador"),
                            ),
                          ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      onPressed: () => _mostrarModalEditarUsuario(u),
                      tooltip: "Editar datos del usuario",
                    ),
                    IconButton(
                      icon: const Icon(Icons.lock_reset, color: Colors.orange),
                      tooltip: "Resetear Contraseña",
                      onPressed:
                          () => _mostrarDialogoResetPassword(
                            u['id'],
                            u['nombre'],
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoResetPassword(String id, String nombre) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Nueva contraseña para $nombre"),
            content: TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Escribe la nueva contraseña",
                hintText: "Mínimo 6 caracteres",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (passCtrl.text.length < 6) {
                    AppService.showAlert("Demasiado corta");
                    return;
                  }
                  Navigator.pop(context);
                  AppService.runWithLoading(() async {
                    await UsuarioService().adminActualizarPassword(
                      id,
                      passCtrl.text,
                    );
                    AppService.showAlert("Contraseña cambiada con éxito");
                  });
                },
                child: const Text("Confirmar Cambio"),
              ),
            ],
          ),
    );
  }

  void _mostrarModalEditarUsuario(Map<String, dynamic> u) {
    final nombreCtrl = TextEditingController(text: u['nombre']);
    final mailCtrl = TextEditingController(text: u['mail']);
    final razonCtrl = TextEditingController(text: u['razon_social']);
    final rutCtrl = TextEditingController(text: u['rut']);
    final celCtrl = TextEditingController(text: u['celular']);
    final dirCtrl = TextEditingController(text: u['direccion']);
    String? localidadId = u['localidad_id']?.toString();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Editar Perfil: ${u['nombre']}"),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            nombreCtrl,
                            "Nombre",
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(mailCtrl, "Email", Icons.email),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            razonCtrl,
                            "Razón Social",
                            Icons.business,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(rutCtrl, "RUT / ID", Icons.badge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildInput(celCtrl, "Celular", Icons.phone_android),
                    const SizedBox(height: 15),
                    _buildInput(dirCtrl, "Dirección", Icons.map),
                    const SizedBox(height: 15),

                    // Selector de Localidad dentro del modal
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: LocalidadService().fetchLocalidades(),
                      builder: (context, snapshot) {
                        return DropdownButtonFormField<String>(
                          value: localidadId,
                          decoration: const InputDecoration(
                            labelText: "Localidad",
                            border: OutlineInputBorder(),
                          ),
                          items:
                              (snapshot.data ?? [])
                                  .map(
                                    (loc) => DropdownMenuItem(
                                      value: loc['id'].toString(),
                                      child: Text(loc['nombre']),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) => localidadId = val,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nuevosDatos = {
                    'nombre': nombreCtrl.text,
                    'mail': mailCtrl.text,
                    'razon_social': razonCtrl.text,
                    'rut': rutCtrl.text,
                    'celular': celCtrl.text,
                    'direccion': dirCtrl.text,
                    'localidad_id': localidadId,
                  };

                  AppService.runWithLoading(() async {
                    await UsuarioService().actualizarDatosPerfil(
                      userId: u['id'],
                      nuevosDatos: nuevosDatos,
                    );
                    Navigator.pop(context);
                    setState(() {}); // Refrescar tabla
                    AppService.showAlert("Datos actualizados correctamente");
                  });
                },
                child: const Text("Guardar Cambios"),
              ),
            ],
          ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool caps = false,
  }) {
    return TextFormField(
      controller: ctrl,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? "Requerido" : null,
    );
  }

  Widget _roleBadge(String? rol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "ROL: ${rol?.toUpperCase()}",
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }
}
