import 'package:demos/models/transportista.dart';
import 'package:demos/models/vehiculo.dart';
import 'package:demos/services/app_state.dart';
import 'package:demos/services/db/localidades_service.dart';
import 'package:demos/services/db/transportista_service.dart';
import 'package:demos/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NuevoTransportistaPage extends StatefulWidget {
  const NuevoTransportistaPage({super.key});

  @override
  State<NuevoTransportistaPage> createState() => _NuevoTransportistaPageState();
}

class _NuevoTransportistaPageState extends State<NuevoTransportistaPage> {
  final _formKey = GlobalKey<FormState>();

  // Datos Transportista
  final _nombreCtrl = TextEditingController();
  final _razonCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  String? _localidadId;
  List<Map<String, dynamic>> _localidades = [];
  String? _localidadSeleccionadaId;
  bool _loadingLocalidades = true;
  // Lista temporal de vehículos
  final List<Vehiculo> _flotaTemporal = [];
  List<String> _tiposDisponibles = [];
  bool _loadingTipos = true;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    _cargarLocalidades();
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await TransportistaService().fetchTiposVehiculo();
      setState(() {
        _tiposDisponibles = tipos;
        _loadingTipos = false;
      });
    } catch (e) {
      AppService.showAlert("Error al cargar tipos de vehículo");
    }
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

  void _agregarVehiculoALista(Vehiculo v) {
    setState(() => _flotaTemporal.add(v));
  }

  Future<void> _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;

    AppService.runWithLoading(() async {
      final nuevoT = Transportista(
        id: '', // Supabase generará el UUID
        nombre: _nombreCtrl.text,
        razonSocial: _razonCtrl.text,
        telefono: _telCtrl.text,
        localidadId: _localidadSeleccionadaId,
        observaciones: _obsCtrl.text,
        direccion: _dirCtrl.text,
        vehiculos: _flotaTemporal, // Pasamos la lista que llenamos con el modal
      );

      final nuevoId = await TransportistaService().guardarTransportistaCompleto(
        nuevoT,
        _flotaTemporal,
      );
      AppService.showAlert("Transportista y flota registrados");
      // if (mounted) context.go('/transportistas');
      if (mounted) {
        // Volvemos a la lista pasando el ID recién creado
        context.go('/transportistas?newId=$nuevoId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Nuevo Registro Logístico",
      icon: Icons.add_business,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COLUMNA 1: DATOS EMPRESA
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      "Datos de la Empresa",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nombre Fantasía",
                      ),
                    ),
                    TextFormField(
                      controller: _razonCtrl,
                      decoration: const InputDecoration(
                        labelText: "Razón Social",
                      ),
                    ),
                    TextFormField(
                      controller: _dirCtrl,
                      decoration: const InputDecoration(labelText: "Direccion"),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child:
                              _loadingLocalidades
                                  ? const LinearProgressIndicator()
                                  : DropdownButtonFormField<String>(
                                    value: _localidadSeleccionadaId,
                                    decoration: const InputDecoration(
                                      labelText: "Localidad",
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
                                          () => _localidadSeleccionadaId = val,
                                        ),
                                    validator:
                                        (val) =>
                                            val == null ? "Requerido" : null,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        // BOTÓN PARA CREAR NUEVA LOCALIDAD
                        IconButton.filledTonal(
                          onPressed: _abrirDialogoNuevaLocalidad,
                          icon: const Icon(Icons.add),
                          tooltip: "Crear nueva localidad",
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _telCtrl,
                      decoration: const InputDecoration(labelText: "Teléfono"),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _obsCtrl,
                      maxLines:
                          4, // Permite ver 4 líneas de texto simultáneamente
                      minLines: 2, // Altura mínima inicial
                      decoration: InputDecoration(
                        labelText: "Observaciones Generales",
                        hintText:
                            "Ej: Solo entregas matutinas, requiere aviso previo...",
                        prefixIcon: const Icon(Icons.note_add_outlined),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint:
                            true, // Alinea la etiqueta arriba cuando hay muchas líneas
                      ),
                    ),
                    // Aquí iría tu Dropdown de Localidades...
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 40),
            // COLUMNA 2: FLOTA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Vehículos a Vincular",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            () =>
                                _abrirModalNuevoVehiculo(), // Usamos el modal que ya tienes
                        icon: const Icon(Icons.add),
                        label: const Text("Añadir Camión"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _flotaTemporal.length,
                      itemBuilder:
                          (context, i) => Card(
                            child: ListTile(
                              title: Text(_flotaTemporal[i].patente),
                              subtitle: Text(_flotaTemporal[i].modelo),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _flotaTemporal.removeAt(i),
                                    ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _guardarTodo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("FINALIZAR REGISTRO"),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  void _abrirModalNuevoVehiculo() {
    final formKey = GlobalKey<FormState>();
    final patenteCtrl = TextEditingController();
    final modeloCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController();
    String? tipoSeleccionado = _tiposDisponibles.first; // Lista que cargaremos

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Registrar Vehiculo"),
            // HACER EL MODAL MÁS GRANDE
            content: Container(
              width: 600, // Ancho fijo mayor para Web
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              patenteCtrl,
                              "Patente",
                              Icons.badge,
                              caps: true,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildInput(
                              modeloCtrl,
                              "Modelo",
                              Icons.directions_car,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInput(
                              capacidadCtrl,
                              "Capacidad (Ton)",
                              Icons.fitness_center,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // SELECTOR DE TIPO CON BOTÓN +
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child:
                                      _loadingTipos
                                          ? const CircularProgressIndicator()
                                          : DropdownButtonFormField<String>(
                                            value:
                                                _tiposDisponibles.contains(
                                                      tipoSeleccionado,
                                                    )
                                                    ? tipoSeleccionado
                                                    : _tiposDisponibles.first,
                                            items:
                                                _tiposDisponibles
                                                    .map(
                                                      (t) => DropdownMenuItem(
                                                        value: t,
                                                        child: Text(t),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (v) => setState(
                                                  () => tipoSeleccionado = v!,
                                                ),
                                          ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: () => _dialogoNuevoTipo(),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      _flotaTemporal.add(
                        Vehiculo(
                          id: "",
                          patente: patenteCtrl.text.toUpperCase(),
                          modelo: modeloCtrl.text,
                          capacidad: "${capacidadCtrl.text} Ton",
                          tipo: tipoSeleccionado!,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Agregar a la lista"),
              ),
            ],
          ),
    );
  }

  void _dialogoNuevoTipo() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Nuevo Tipo de Vehículo"),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: "Ej: Mosquito, Tanque...",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    setState(
                      () => _tiposDisponibles.add(ctrl.text),
                    ); // Agrega a la lista local
                    Navigator.pop(context);
                  }
                },
                child: const Text("Añadir"),
              ),
            ],
          ),
    );
  }

  // Widget auxiliar para inputs limpios
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
