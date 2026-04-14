import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/models/vehiculo.dart';
import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/services/db/transportista_service.dart';
import 'package:cargasuy/services/db/vehiculo_service.dart';
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
  List<String> _tiposDisponibles = [];
  bool _loadingTipos = true;

  Future<void> _cargarFlota() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final rol = userRole.value;

      var query = Supabase.instance.client
          .from('vehiculos')
          .select('*, transportistas(nombre)');

      if (rol == UserRole.transportista) {
        query = query.eq('transportista_id', user!.id);
      }

      final response = await query.order('patente', ascending: true);

      final List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        // MAPEAMOS CON CUIDADO PARA EVITAR EL ERROR DE NULL
        _datosFlota =
            rawData.map((json) {
              return {
                'id': json['id'],
                'vehiculo': Vehiculo(
                  id: json['id'] ?? '',
                  patente: json['patente'] ?? 'S/P',
                  modelo: json['modelo'] ?? 'Genérico',
                  capacidad: "${json['capacidad_ton'] ?? 0} Ton",
                  tipo: json['tipo'] ?? 'S/T',
                ),
                'dueno': json['transportistas']?['nombre'] ?? 'Sin Empresa',
              };
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error detallado: $e");
    }
  }

  void initState() {
    super.initState();
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final bool esTransportista = userRole.value == UserRole.transportista;

    return Scaffold(
      floatingActionButton:
          esTransportista
              ? FloatingActionButton.extended(
                // Usamos una función anónima limpia
                onPressed: () {
                  _abrirModalNuevoVehiculo(context);
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
                  final v = item['vehiculo'] as Vehiculo;
                  final dueno = item['dueno'] as String;
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
                        _cell(v.patente, 150, isBold: true),
                        _cell(v.modelo, 200),
                        _cell(v.capacidad, 120),

                        // _cellInteractive(context, dueno, 250, () {
                        //   context.go('/transportistas?nombre=$dueno');
                        // }),
                        if (userRole.value == UserRole.admin)
                          _cellInteractive(context, item['dueno'], 250, () {
                            final nombreUri = Uri.encodeComponent(
                              item['dueno'],
                            ); // Codifica espacios y caracteres
                            context.go('/transportistas?nombre=$nombreUri');
                          }),
                        // _cell(dueno, 200, color: Colors.indigo), // Dueño resaltado
                        _cell(v.tipo, 120),
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

  void _abrirModalNuevoVehiculo(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final patenteCtrl = TextEditingController();
    final modeloCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController();
    // String? tipoSeleccionado; // Deberás cargar _tiposDisponibles aquí también
    // String? tipoSeleccionado = _tiposDisponibles.first;
    String? tipoSeleccionado =
        _tiposDisponibles.isNotEmpty ? _tiposDisponibles.first : null;

    showDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar haciendo clic fuera
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Nueva Unidad Técnica"),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(patenteCtrl, "Patente", Icons.badge, caps: true),
                  const SizedBox(height: 15),
                  _buildInput(
                    modeloCtrl,
                    "Modelo / Marca",
                    Icons.local_shipping,
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
                                ? const Text("Cargando tipos de vehículo...")
                                : DropdownButtonFormField<String>(
                                  value: tipoSeleccionado,
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
                                      (v) =>
                                          setState(() => tipoSeleccionado = v),
                                  decoration: const InputDecoration(
                                    labelText: "Tipo de Vehículo",
                                    border: OutlineInputBorder(),
                                  ),
                                  validator:
                                      (v) => v == null ? "Requerido" : null,
                                ),
                      ),
                      // Expanded(
                      //   child: DropdownButtonFormField<String>(
                      //     decoration: const InputDecoration(
                      //       labelText: "Tipo",
                      //       border: OutlineInputBorder(),
                      //     ),
                      //     items:
                      //         _tiposDisponibles
                      //             .map(
                      //               (t) => DropdownMenuItem(
                      //                 value: t,
                      //                 child: Text(t),
                      //               ),
                      //             )
                      //             .toList(),
                      //     onChanged: (v) => tipoSeleccionado = v,
                      //     validator: (v) => v == null ? "Requerido" : null,
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final vehiculoData = {
                    'transportista_id':
                        Supabase.instance.client.auth.currentUser!.id,
                    'patente': patenteCtrl.text.toUpperCase(),
                    'modelo': modeloCtrl.text,
                    'capacidad_ton': double.parse(capacidadCtrl.text),
                    'tipo': tipoSeleccionado,
                  };

                  AppService.runWithLoading(() async {
                    await Supabase.instance.client
                        .from('vehiculos')
                        .insert(vehiculoData);
                    Navigator.of(dialogContext).pop();
                    _cargarFlota(); // Refrescamos la lista de la página
                    AppService.showAlert("Vehículo registrado con éxito");
                  });
                }
              },
              child: const Text("Guardar en mi Flota"),
            ),
          ],
        );
      },
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
    // 1. Si el buscador está vacío, devolvemos toda la lista cargada
    if (_queryFlota.isEmpty) return _datosFlota;

    final q = _queryFlota.toLowerCase();

    // 2. Filtramos la lista principal
    return _datosFlota.where((item) {
      // Extraemos el objeto vehículo del mapa
      final v = item['vehiculo'] as Vehiculo;
      final dueno = item['dueno'].toString().toLowerCase();

      // Buscamos coincidencia en patente, modelo o nombre del dueño
      return v.patente.toLowerCase().contains(q) ||
          v.modelo.toLowerCase().contains(q) ||
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
          _cell("Patente", 150, isBold: true),
          _cell("Modelo", 200, isBold: true),
          _cell("Capacidad", 120, isBold: true),
          if (userRole.value == UserRole.admin)
            _cell("Transportista", 250, isBold: true),
          _cell("Tipo", 120, isBold: true),
        ],
      ),
    );
  }
}
