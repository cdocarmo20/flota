import 'package:cargasuy/models/marcas_vehiculo.dart';
import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/models/vehiculo.dart';
import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/services/db/transportista_service.dart';
import 'package:cargasuy/services/db/vehiculo_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/page_layout.dart';
import '../models/transportista.dart';

class FlotaPage extends StatefulWidget {
  const FlotaPage({super.key});

  @override
  State<FlotaPage> createState() => _FlotaPageState();
}

class _FlotaPageState extends State<FlotaPage> {
  final _service = VehiculoService();
  List<Map<String, dynamic>> _datosFlota = [];
  bool _isLoading = true;
  String _queryFlota = "";
  List<Map<String, dynamic>> _tiposDisponibles = [];
  bool _loadingTipos = true;
  List<MarcaVehiculo> _listaMarcas = [];
  String? _marcaSeleccionadaId;

  final user = Supabase.instance.client.auth.currentUser;

  Future<void> _cargarFlota() async {
    setState(() => _isLoading = true);
    try {
      final rol = userRole.value;
      final data = await VehiculoService().obtenerVehiculos(
        userRole.value!,
        user!.id,
      );
      setState(() {
        _datosFlota = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error detallado: $e");
    }
  }

  Future<void> _cargarMarcas() async {
    final data = await VehiculoService().obtenerMarcas();

    setState(() {
      final Map<String, MarcaVehiculo> marcasUnicas = {};
      for (var m in data) {
        marcasUnicas[m['id']] = MarcaVehiculo(id: m['id'], nombre: m['nombre']);
      }
      _listaMarcas = marcasUnicas.values.toList();
    });
  }

  void initState() {
    super.initState();
    _cargarMarcas();
    _cargarTipos();
    _cargarFlota();
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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    Widget contenido = vehiculosContent();
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text("Flota de Vehículos")),
        body: contenido,
      );
    } else {
      return PageLayout(
        title: "Flota de Vehículos",
        icon: Icons.local_shipping_rounded,
        child: contenido,
      );
    }
  }

  Widget vehiculosContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final bool esTransportista = userRole.value == UserRole.transportista;

    return Scaffold(
      floatingActionButton:
          esTransportista
              ? FloatingActionButton.extended(
                // Usamos una función anónima limpia
                onPressed: () {
                  _abrirEditorVehiculo(null);
                },
                label: const Text("Nueva Unidad"),
                icon: const Icon(Icons.add_road),
                backgroundColor: Colors.indigo,
              )
              : null,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _queryFlota = val),
                decoration: const InputDecoration(
                  hintText: "Buscar patente, modelo o dueño...",
                  prefixIcon: Icon(Icons.search, color: Colors.indigo),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            // CABECERA DE LA TABLA
            _buildHeaderTable(),
            const Divider(),

            // CUERPO DE LA TABLA
            Expanded(
              child: ListView.builder(
                itemCount: _datosFiltrados.length,
                itemBuilder: (context, index) {
                  final item = _datosFiltrados[index];

                  final v = item['id'] != null ? Vehiculo.fromJson(item) : null;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _cell(
                            v!.patente.toString(),
                            100,
                            isBold: true,
                          ),
                        ),
                        Expanded(child: _cell(v.modelo.toString(), 150)),
                        Expanded(child: _cell(v.marcaNombre.toString(), 150)),
                        Expanded(child: _cell(v.capacidad.toString(), 100)),

                        if (userRole.value == UserRole.admin)
                          Expanded(
                            child: _cellInteractive(
                              context,
                              v.dueno.toString(),
                              250,
                              () {
                                final nombreUri = Uri.encodeComponent(
                                  v.dueno.toString(),
                                ); // Codifica espacios y caracteres
                                context.go('/transportistas?nombre=$nombreUri');
                              },
                            ),
                          ),
                        // _cell(dueno, 200, color: Colors.indigo), // Dueño resaltado
                        Flexible(child: _cell(v.tipo.toString(), 120)),

                        Expanded(
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              // Aquí llamas a la función para abrir el formulario de edición
                              _abrirEditorVehiculo(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarVehiculo(String vehiculoId, String patente) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Confirmar Baja"),
                content: Text(
                  "¿Estás seguro de eliminar el vehículo con patente $patente? Esta acción no se puede deshacer.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancelar"),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Eliminar"),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmar) {
      AppService.runWithLoading(() async {
        try {
          await Supabase.instance.client
              .from('vehiculos')
              .delete()
              .eq('id', vehiculoId);

          _cargarFlota(); // Recargamos la lista
          AppService.showAlert("Vehículo eliminado correctamente");
        } catch (e) {
          AppService.showAlert(
            "No se pudo eliminar: El vehículo puede estar asignado a un viaje.",
          );
        }
      });
    }
  }

  void _abrirEditorVehiculo(Vehiculo? vehiculo) {
    // Seteamos la marca inicial (si estamos editando)

    _marcaSeleccionadaId = vehiculo?.marcaId;
    print(vehiculo?.tipo);
    final anioCtrl = TextEditingController(
      text: vehiculo?.anio?.toString() ?? "",
    );
    final patenteCtrl = TextEditingController(text: vehiculo?.patente ?? "");
    final modeloCtrl = TextEditingController(text: vehiculo?.modelo ?? "");
    final capacidadCtrl = TextEditingController(
      text: vehiculo?.capacidad ?? "",
    );
    String? tipoSeleccionado = vehiculo?.tipoId;

    if (tipoSeleccionado == '' && _tiposDisponibles.isNotEmpty) {
      tipoSeleccionado = _tiposDisponibles.first['id'].toString();
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                vehiculo == null ? "Nuevo Vehículo" : "Editar Vehículo",
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // DROPDOWN DE MARCAS
                    _buildInput(
                      patenteCtrl,
                      "Patente",
                      Icons.badge,
                      caps: true,
                    ),
                    const SizedBox(height: 15),
                    _buildInput(modeloCtrl, "Modelo", Icons.local_shipping),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: Key(_marcaSeleccionadaId ?? 'vacio'),
                            value: _marcaSeleccionadaId,
                            decoration: const InputDecoration(
                              labelText: "Marca",
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              ..._listaMarcas.map(
                                (m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.nombre),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: "OPCION_NUEVA",
                                child: Text(
                                  "+ Agregar nueva marca...",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                            onChanged: (val) async {
                              if (val == "OPCION_NUEVA") {
                                setState(() => _marcaSeleccionadaId = null);
                                String? nombre =
                                    await _pedirNombreMarcaDialogo();
                                if (nombre != null &&
                                    nombre.trim().isNotEmpty) {
                                  final nuevaMarcaMap = await VehiculoService()
                                      .crearMarca(nombre.trim());

                                  final nuevasMarcasData =
                                      await VehiculoService().obtenerMarcas();
                                  setDialogState(() {
                                    _listaMarcas =
                                        nuevasMarcasData
                                            .map(
                                              (m) => MarcaVehiculo(
                                                id: m['id'],
                                                nombre: m['nombre'],
                                              ),
                                            )
                                            .toList();
                                    _marcaSeleccionadaId = nuevaMarcaMap['id'];
                                  });
                                } else {
                                  // Si canceló, reseteamos el dropdown a null o al valor anterior
                                  setState(() => _marcaSeleccionadaId = null);
                                }
                              } else {
                                setState(() => _marcaSeleccionadaId = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(
                            anioCtrl,
                            "Año",
                            Icons.date_range_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            capacidadCtrl,
                            "Capacidad (Ton)",
                            Icons.fitness_center,
                            // isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              _tiposDisponibles.isEmpty
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : DropdownButtonFormField<String>(
                                    // 1. Buscamos si el ID seleccionado existe en la lista de mapas
                                    // Comparamos contra t['id'], no contra el nombre
                                    value:
                                        _tiposDisponibles.any(
                                              (t) =>
                                                  t['id'].toString() ==
                                                  tipoSeleccionado,
                                            )
                                            ? tipoSeleccionado
                                            : (_tiposDisponibles.isNotEmpty
                                                ? _tiposDisponibles.first['id']
                                                    .toString()
                                                : null),

                                    decoration: const InputDecoration(
                                      labelText: "Tipo de Vehículo",
                                      border: OutlineInputBorder(),
                                    ),

                                    // 2. IMPORTANTE: El value del Item DEBE SER el ID
                                    items:
                                        _tiposDisponibles.map((t) {
                                          return DropdownMenuItem<String>(
                                            value:
                                                t['id']
                                                    .toString(), // <--- Esto debe ser el UUID/ID
                                            child: Text(
                                              t['nombre'],
                                            ), // <--- Esto es lo que el usuario lee
                                          );
                                        }).toList(),

                                    onChanged: (v) {
                                      setState(() {
                                        tipoSeleccionado =
                                            v; // Guardamos el ID seleccionado
                                      });
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed:
                      () => _guardarVehiculo(
                        contextDialogo: context,
                        id: vehiculo?.id, // Si es nulo, crea uno nuevo
                        patente: patenteCtrl.text,
                        modelo: modeloCtrl.text,
                        capacidad: capacidadCtrl.text,
                        tipo: tipoSeleccionado.toString(),
                        anio: anioCtrl.text,
                        marcaId: _marcaSeleccionadaId,
                      ),
                  child: const Text("GUARDAR"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _pedirNombreMarcaDialogo() async {
    String? nombreNuevo;
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Nueva Marca"),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: "Ej: Scania"),
              onChanged: (val) => nombreNuevo = val,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, nombreNuevo),
                child: const Text("AÑADIR"),
              ),
            ],
          ),
    );
  }

  Future<void> _guardarVehiculo({
    required BuildContext contextDialogo,
    String? id,
    required String patente,
    required String modelo,
    required String capacidad,
    required String tipo,
    required String? anio,
    required String? marcaId,
  }) async {
    // Validación básica
    if (marcaId == null || patente.isEmpty || anio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa Marca, Patente y Año"),
        ),
      );
      return;
    }
    try {
      await VehiculoService().guardarVehiculo(
        id: id,
        patente: patente,
        modelo: modelo,
        capacidad: capacidad,
        tipo: tipo,
        anio: int.parse(anio),
        marcaId: marcaId,
        userID: user!.id,
      );
      if (mounted) {
        Navigator.pop(contextDialogo);
        _cargarFlota(); // Refresca la lista principal
        AppService.showAlert(
          id == null ? "Vehículo creado" : "Vehículo actualizado",
        );
      }
    } catch (e) {
      print("Error al guardar: $e");
      AppService.showAlert("Error al guardar los datos!");
    }
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

  Widget _cellInteractive(
    BuildContext context,
    String text,
    double width,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message:
              "Ver ficha completa de $text", // Mensaje que aparecerá al pasar el mouse
          waitDuration: const Duration(
            milliseconds: 500,
          ), // Retraso para que no sea molesto
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.business_center_outlined,
                    size: 14,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: Colors.indigo,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _datosFiltrados {
    if (_queryFlota.isEmpty) return _datosFlota;

    final q = _queryFlota.toLowerCase();

    return _datosFlota.where((item) {
      // Usamos ?? '' para que si el campo es null, no rompa el .toLowerCase()
      final patente = (item['patente'] ?? '').toString().toLowerCase();
      final modelo = (item['modelo'] ?? '').toString().toLowerCase();
      // Acceso seguro a la marca anidada
      final marca =
          (item['marcas_vehiculos']?['nombre'] ?? '').toString().toLowerCase();
      // Si tienes un campo dueño, asegúrate de que la llave sea la correcta
      final dueno = (item['dueno'] ?? '').toString().toLowerCase();

      return patente.contains(q) ||
          modelo.contains(q) ||
          marca.contains(q) ||
          dueno.contains(q);
    }).toList();
  }

  // Función para transformar los datos
  List<Map<String, dynamic>> _listaVehiculosUnificada(
    List<Transportista> _listaTransportistas,
  ) {
    List<Map<String, dynamic>> unificada = [];
    for (var t in _listaTransportistas) {
      for (var v in t.vehiculos) {
        unificada.add({
          'vehiculo': v,
          'dueno': t.nombre,
          'contacto': t.telefono,
        });
      }
    }
    return unificada;
  }

  Widget _cell(String text, double width, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHeaderTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(child: _cell("Patente", 100, isBold: true)),
          Expanded(child: _cell("Modelo", 150, isBold: true)),
          Expanded(child: _cell("Marca", 150, isBold: true)),
          Expanded(child: _cell("Capacidad", 100, isBold: true)),
          if (userRole.value == UserRole.admin)
            Expanded(child: _cell("Transportista", 200, isBold: true)),
          Expanded(child: _cell("Tipo", 120, isBold: true)),
        ],
      ),
    );
  }
}
