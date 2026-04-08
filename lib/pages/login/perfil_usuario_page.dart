import 'package:demos/services/app_state.dart';
import 'package:demos/services/db/localidades_service.dart';
import 'package:demos/services/db/usuario_service.dart';
import 'package:demos/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({super.key});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  String? _localidadId;
  bool _isLoading = true;
  bool _loadingLocalidades = true;
  String? _localidadSeleccionadaId;
  List<Map<String, dynamic>> _localidades = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosActuales();
    _cargarLocalidades();
  }

  Future<void> _cargarLocalidades() async {
    try {
      final datos = await LocalidadService().fetchLocalidades();
      setState(() {
        _localidades = datos;
        _loadingLocalidades = false;
      });
    } catch (e) {
      AppService.showAlert("Error al cargar ciudades");
    }
  }

  Future<void> _cargarDatosActuales() async {
    final user = Supabase.instance.client.auth.currentUser;
    final data =
        await Supabase.instance.client
            .from('clientes')
            .select()
            .eq('id', user!.id)
            .single();

    setState(() {
      _nombreCtrl.text = data['nombre'] ?? '';
      _telCtrl.text = data['telefono'] ?? '';
      _dirCtrl.text = data['direccion'] ?? '';
      _localidadId = data['localidad_id'];
      _isLoading = false;
    });
  }

  void _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    AppService.runWithLoading(() async {
      await UsuarioService().actualizarPerfil(
        nombre: _nombreCtrl.text,
        telefono: _telCtrl.text,
        direccion: _dirCtrl.text,
        localidadId: _localidadId,
      );
      AppService.showAlert("Perfil actualizado con éxito");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return PageLayout(
      title: "Mi Perfil",
      icon: Icons.account_circle_outlined,
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              "Datos de contacto",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildInput(_nombreCtrl, "Nombre Completo", Icons.person),
            const SizedBox(height: 15),
            _buildInput(_telCtrl, "Teléfono / WhatsApp", Icons.phone),
            const SizedBox(height: 15),
            _buildInput(_dirCtrl, "Dirección Laboral", Icons.map),
            const SizedBox(height: 30),

            // Reutilizamos tu selector de localidades
            _buildLocalidadSelector(),

            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text("GUARDAR MI INFORMACIÓN"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ubicación", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                // Reutilizamos el servicio que ya carga localidades de Supabase
                future: LocalidadService().fetchLocalidades(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  return DropdownButtonFormField<String>(
                    value:
                        _localidadId, // La ID que cargamos de la tabla clientes
                    decoration: const InputDecoration(
                      labelText: "Ciudad / Localidad",
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        snapshot.data!.map((loc) {
                          return DropdownMenuItem(
                            value: loc['id'].toString(),
                            child: Text(loc['nombre']),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => _localidadId = val),
                    validator:
                        (val) => val == null ? "Selecciona tu ciudad" : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            // Botón para agregar una nueva ciudad si no existe
            IconButton.filledTonal(
              onPressed:
                  () =>
                      _abrirDialogoNuevaLocalidad(), // La función que ya creamos antes
              icon: const Icon(Icons.add),
              tooltip: "Añadir ciudad",
            ),
          ],
        ),
      ],
    );
  }

  void _abrirDialogoNuevaLocalidad() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Nueva Localidad"),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: "Nombre de la ciudad",
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.isEmpty) return;
                  Navigator.pop(context); // Cierra el modal

                  AppService.runWithLoading(() async {
                    final nuevaLoc = await LocalidadService().crearLocalidad(
                      ctrl.text,
                    );
                    await _cargarLocalidades(); // Refrescamos la lista del dropdown
                    setState(() {
                      _localidadSeleccionadaId =
                          nuevaLoc['id'].toString(); // La seleccionamos
                    });
                    AppService.showAlert("Ciudad creada: ${ctrl.text}");
                  });
                },
                child: const Text("Crear"),
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
}
