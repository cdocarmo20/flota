import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/services/db/vehiculo_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicarVehiculosPage extends StatefulWidget {
  const PublicarVehiculosPage({super.key});

  @override
  State<PublicarVehiculosPage> createState() =>
      _PublicarDisponibilidadPageState();
}

class _PublicarDisponibilidadPageState extends State<PublicarVehiculosPage> {
  final supabase = Supabase.instance.client;

  // Datos del formulario
  String? _vehiculoId;
  String? _origenNombre;
  String? _destinoNombre;
  DateTime? _fechaSeleccionada;
  final TextEditingController _descController = TextEditingController();
  List<String> _listaNombresCiudades = [];
  List<Map<String, dynamic>> _misVehiculos = [];
  bool _cargando = true;
  bool _cargandoLocalidades = true;
  final user = Supabase.instance.client.auth.currentUser;
  @override
  void initState() {
    super.initState();
    _cargarLocalidades();
    _cargarDatosIniciales();
  }

  Future<void> _cargarLocalidades() async {
    try {
      final localidades = await LocalidadService().fetchLocalidades();
      String? ciudadDelUsuario = userLocalidad.value!['nombre'].toString();
      setState(() {
        _listaNombresCiudades =
            localidades.map((l) => l['nombre'] as String).toList();
        // for (var l in localidades) {
        //   _coordenadasCiudades[l['nombre']] = LatLng(
        //     (l['latitud'] as num).toDouble(),
        //     (l['longitud'] as num).toDouble(),
        //   );
        //   _mapaIdsCiudades[l['nombre']] = l['id'];
        // }
        if (_listaNombresCiudades.contains(ciudadDelUsuario)) {
          _origenNombre = ciudadDelUsuario;
        }

        _cargandoLocalidades = false;
      });
    } catch (e) {
      print(e);
      AppService.showAlert("Error al cargar localidades");
      setState(() => _cargandoLocalidades = false);
    }
  }

  Future<void> _cargarDatosIniciales() async {
    // final userId = Supabase.instance.client.auth.currentUser.id;

    final rol = userRole.value;
    final data = await VehiculoService().obtenerVehiculos(
      userRole.value!,
      user!.id,
    );
    setState(() {
      _misVehiculos = List<Map<String, dynamic>>.from(data);
      _cargando = false;
    });
  }

  Future<void> _guardarPublicacion() async {
    // 1. Validaciones de UI
    if (_vehiculoId == null ||
        _origenNombre == null ||
        _destinoNombre == null ||
        _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Por favor completa todos los campos")),
      );
      return;
    }

    try {
      final idOrigen = await LocalidadService().obtenerIdLocalidad(
        _origenNombre!,
      );
      final idDestino = await LocalidadService().obtenerIdLocalidad(
        _destinoNombre!,
      );

      // 3. Llamada al servicio externo
      await ViajesService().crearViajeVehiculo(
        vehiculoId: _vehiculoId!,
        idOrigen: idOrigen,
        idDestino: idDestino,
        fecha: _fechaSeleccionada!,
        descripcion: _descController.text,
      );

      if (mounted) {
        context.go('/mis-viajes');
        AppService.showAlert("Viaje publicado con éxito!");
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("✅ Viaje publicado con éxito")),
        // );
      }
    } catch (e) {
      print(e);
      AppService.showAlert("❌ Error al guardar: $e");
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text("❌ Error al guardar: $e")));
    }
  }

  // Simulación de búsqueda de ID (Deberías usar tu lista _localidades)
  Future<String> _obtenerIdLocalidad(String nombre) async {
    final res =
        await supabase
            .from('localidades')
            .select('id')
            .eq('nombre', nombre)
            .single();
    return res['id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    Widget contenido = vehiculosContent();
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text("Publicar mi Vehículos")),
        body: contenido,
      );
    } else {
      return PageLayout(
        title: "Publicar mi Vehículos",
        icon: Icons.airport_shuttle_outlined,
        child: contenido,
      );
    }
  }

  Widget vehiculosContent() {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector de Vehículo
          const Text(
            "¿Qué vehículo vas a usar?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _vehiculoId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.local_shipping),
            ),
            items:
                _misVehiculos
                    .map(
                      (v) => DropdownMenuItem(
                        value: v['id'].toString(),
                        child: Text("${v['modelo']} - ${v['patente']}"),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _vehiculoId = val),
          ),

          const SizedBox(height: 25),

          // 2. Origen (Usando tu widget con Autocomplete)
          _seccionUbicacion(
            titulo: "Desde dónde salís",
            esOrigen: true,
            localidad: _origenNombre,
            onLocalidadChanged: (val) => setState(() => _origenNombre = val),
            // Aquí van los demás parámetros de tu widget...
            direccion: null,
            onMapaConfirmado: (l, s) {},
          ),

          const SizedBox(height: 20),

          // 3. Destino
          _seccionUbicacion(
            titulo: "Hacia dónde vas",
            esOrigen: false,
            localidad: _destinoNombre,
            onLocalidadChanged: (val) => setState(() => _destinoNombre = val),
            direccion: null,
            onMapaConfirmado: (l, s) {},
          ),

          const SizedBox(height: 25),

          // 4. Fecha del viaje
          const Text(
            "Fecha del viaje",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            leading: const Icon(Icons.calendar_month),
            title: Text(
              _fechaSeleccionada == null
                  ? "Seleccionar fecha"
                  : "${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}",
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _fechaSeleccionada = picked);
            },
          ),

          const SizedBox(height: 40),

          // Botones de acción (Confirmar / Cancelar)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text("CANCELAR"),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _guardarPublicacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("PUBLICAR"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccionUbicacion({
    required bool esOrigen,
    required String titulo,
    required String? localidad,
    required String? direccion,
    required Function(String?) onLocalidadChanged,
    required Function(LatLng, String) onMapaConfirmado,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // 1. Selector de Localidad con Autocomplete
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: localidad ?? ''),

                  // 1. Filtrado de opciones
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty)
                      return const Iterable<String>.empty();
                    return _listaNombresCiudades.where(
                      (option) => option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },

                  // 2. Campo de texto (Buscador)
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Escribí la ciudad...",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon:
                            controller.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    controller.clear();
                                    onLocalidadChanged(null);
                                  },
                                )
                                : null,
                      ),
                    );
                  },

                  // 3. PERSONALIZACIÓN DEL LISTADO DESPLEGABLE
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment:
                          Alignment.topLeft, // Alinea la lista justo debajo
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 300,
                            maxHeight: 200,
                          ), // Mismo ancho que el buscador
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },

                  onSelected:
                      (String selection) => onLocalidadChanged(selection),
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.add_location_alt, color: Colors.blue),
              tooltip: "Crear nueva localidad",
              onPressed: _mostrarDialogoNuevaLocalidad,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 2. Selector de Punto Exacto
        // if (localidad != null)
        //   InkWell(
        //     onTap: () => _abrirMapaPopup(esOrigen: esOrigen),
        //     child: Container(
        //       padding: const EdgeInsets.all(12),
        //       decoration: BoxDecoration(
        //         color: Colors.blue.withOpacity(0.05),
        //         borderRadius: BorderRadius.circular(10),
        //         border: Border.all(color: Colors.blue.withOpacity(0.2)),
        //       ),
        //       child: Row(
        //         children: [
        //           Icon(
        //             Icons.location_on,
        //             color: direccion == null ? Colors.grey : Colors.red,
        //           ),
        //           const SizedBox(width: 10),
        //           Expanded(
        //             child: Text(
        //               direccion ?? "Marcá el punto exacto en el mapa",
        //               style: TextStyle(
        //                 fontSize: 14,
        //                 fontWeight:
        //                     direccion == null
        //                         ? FontWeight.normal
        //                         : FontWeight.w600,
        //               ),
        //             ),
        //           ),
        //           const Icon(Icons.map_outlined, size: 20),
        //         ],
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Future<void> _mostrarDialogoNuevaLocalidad() async {
    final nombreCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Agregar Nueva Localidad"),
            content: TextField(
              controller: nombreCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Ej: Salto, Uruguay",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isNotEmpty) {
                    try {
                      // Ajusta el nombre de la tabla y columnas según tu DB
                      await LocalidadService().crearLocalidad(
                        nombreCtrl.text.trim(),
                        0.0,
                        0.0,
                      );

                      // Supabase.instance.client.from('localidades').insert(
                      //   {'nombre': nombreCtrl.text.trim()},
                      // );

                      if (mounted) {
                        Navigator.pop(context);
                        _cargarLocalidades();
                        AppService.showAlert("Localidad agregada con éxito!");

                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text("Localidad agregada con éxito"),
                        //   ),
                        // );
                      }
                    } catch (e) {
                      print("Error al crear localidad: $e");
                    }
                  }
                },
                child: const Text("GUARDAR"),
              ),
            ],
          ),
    );
  }
}
