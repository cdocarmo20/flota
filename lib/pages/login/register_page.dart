import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/widgets/animated_login_bg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _razonCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  String? _localidadId;
  List<Map<String, dynamic>> _localidades = [];
  bool _loadingLoc = true;
  String _rolSeleccionado = 'cliente';

  @override
  void initState() {
    super.initState();
    _cargarLocalidades();
  }

  Future<void> _cargarLocalidades() async {
    try {
      // Reutilizamos el servicio que ya tienes
      final datos = await LocalidadService().fetchLocalidades();
      setState(() {
        _localidades = datos;
        _loadingLoc = false;
      });
    } catch (e) {
      setState(() => _loadingLoc = false);
    }
  }

  Future<void> _handleRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    AppService.runWithLoading(() async {
      try {
        // Registro en Supabase Auth
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          // Estos datos los recibe el TRIGGER para la tabla clientes
          data: {
            'nombre': _nombreCtrl.text.trim(),
            'razon_social': _razonCtrl.text.trim(),
            'localidad_id': _localidadId,
            'rol': _rolSeleccionado,
            'celular': _celularCtrl.text.trim(),
            'direccion': _direccionCtrl.text.trim(),
            'rut': _rutCtrl.text.trim(),
          },
        );

        AppService.showAlert(
          "Registro exitoso. Espera la aprobación del administrador.",
        );
        if (mounted) context.go('/login');
      } catch (e) {
        AppService.showAlert("Error al registrar: ${e.toString()}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos el fondo animado que creamos antes para el Login
      body: AnimatedLoginBackground(
        child: Center(
          child: Container(
            // Definimos solo el ancho máximo. El alto será flexible.
            width: 500,
            margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            // Scrollbar visible para mejorar la UX en Web
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Importante: Se ajusta al contenido
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 50,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Solicitud de Acceso",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- SELECTOR DE ROL ---
                      const Text(
                        "¿Cómo usarás la plataforma?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'cliente',
                            label: Text("Cliente"),
                            icon: Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: 'transportista',
                            label: Text("Transportista"),
                            icon: Icon(Icons.local_shipping),
                          ),
                        ],
                        selected: {_rolSeleccionado},
                        onSelectionChanged:
                            (Set<String> n) =>
                                setState(() => _rolSeleccionado = n.first),
                      ),

                      const SizedBox(height: 25),

                      // --- CAMPOS DEL FORMULARIO ---
                      _buildInput(_nombreCtrl, "Nombre Completo", Icons.person),

                      const SizedBox(height: 15),
                      _buildInput(
                        _razonCtrl,
                        "Razón Social (Opcional)",
                        Icons.business,
                      ),
                      const SizedBox(height: 15),
                      _buildInput(
                        _direccionCtrl,
                        "Dirección Completa (Opcional)",
                        Icons.home_work_outlined,
                      ),
                      const SizedBox(height: 15),
                      _buildInput(
                        _celularCtrl,
                        "Celular / WhatsApp",
                        Icons.phone_android,
                      ),
                      const SizedBox(height: 15),
                      _buildInput(
                        _rutCtrl,
                        "RUT / Identificación (Opcional)",
                        Icons.description_outlined,
                      ),

                      const SizedBox(height: 15),

                      // Selector de Localidad (El que ya tenemos con FutureBuilder)
                      // Dentro del Column de tu registro_page.dart
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child:
                                _loadingLoc
                                    ? const LinearProgressIndicator()
                                    : DropdownButtonFormField<String>(
                                      value: _localidadId,
                                      decoration: const InputDecoration(
                                        labelText: "Tu Localidad",
                                        prefixIcon: Icon(Icons.location_city),
                                        border: OutlineInputBorder(),
                                      ),
                                      items:
                                          _localidades
                                              .map(
                                                (loc) => DropdownMenuItem(
                                                  value: loc['id'].toString(),
                                                  child: Text(loc['nombre']),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (val) => setState(
                                            () => _localidadId = val,
                                          ),
                                      validator:
                                          (val) =>
                                              val == null
                                                  ? "Selecciona tu ciudad"
                                                  : null,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          // BOTÓN PARA CREAR NUEVA LOCALIDAD
                          IconButton.filledTonal(
                            onPressed: _abrirDialogoNuevaLocalidad,
                            icon: const Icon(Icons.add),
                            tooltip: "Crear nueva ciudad",
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      const SizedBox(height: 15),
                      _buildInput(
                        _emailCtrl,
                        "Email para entrar",
                        Icons.email_outlined,
                      ),
                      const SizedBox(height: 15),
                      _buildInput(
                        _passCtrl,
                        "Contraseña",
                        Icons.lock_outline,
                        isPass: true,
                      ),

                      const SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: _handleRegistro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "ENVIAR SOLICITUD",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
              textCapitalization: TextCapitalization.words,
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
                    try {
                      // 1. Guardar en Supabase
                      final nuevaLoc = await LocalidadService().crearLocalidad(
                        ctrl.text,
                      );

                      // 2. Refrescar la lista de localidades
                      await _cargarLocalidades();

                      // 3. Seleccionar la nueva localidad automáticamente
                      setState(() {
                        _localidadId = nuevaLoc['id'].toString();
                      });

                      AppService.showAlert("Ciudad '${ctrl.text}' agregada");
                    } catch (e) {
                      AppService.showAlert(
                        "La ciudad ya existe o hubo un error",
                      );
                    }
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
    bool isPass = false,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator:
          (v) => v!.isEmpty && !label.contains("Opcional") ? "Requerido" : null,
    );
  }
}
