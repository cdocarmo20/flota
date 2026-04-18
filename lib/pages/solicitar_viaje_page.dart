import 'package:cargasuy/pages/mapa_seleccion_page.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/services/geocoding_web_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../widgets/page_layout.dart';
import 'dart:convert';

import '../services/app_state.dart';

class SolicitarViajePage extends StatefulWidget {
  const SolicitarViajePage({super.key});

  @override
  State<SolicitarViajePage> createState() => _SolicitarViajePageState();
}

class _SolicitarViajePageState extends State<SolicitarViajePage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  double _precioSugerido = 0.0;
  double _tarifaPorTonelada = 1500.0; // Valor ejemplo (puedes cambiarlo)
  DateTime? _fechaSeleccionada;
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _tarifaController = TextEditingController();
  Map<String, LatLng> _coordenadasCiudades = {}; // Para centrar el mapa luego
  List<String> _listaNombresCiudades = [];
  String? _locOrigen; // Guarda el nombre de la ciudad (ej: "Salto")
  String? _dirOrigen; // Guarda la calle y número (ej: "Calle Uruguay 123")
  LatLng? _latLngOrigen; // Guarda las coordenadas exactas para el mapa
  bool _cargandoLocalidades = true;
  // Variables para el DESTINO
  String? _locDestino;
  String? _dirDestino;
  LatLng? _latLngDestino;
  Map<String, String> _mapaIdsCiudades = {}; // Suponiendo que el ID es un int

  @override
  void initState() {
    super.initState();
    _cargarLocalidades();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // No permite fechas pasadas
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Hasta un año a futuro
      locale: const Locale(
        'es',
        'ES',
      ), // Asegúrate de tener configurado el soporte de idiomas
    );

    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        _fechaController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _calcularPrecio() {
    final peso = double.tryParse(_pesoCtrl.text);
    var tarifa = double.tryParse(_tarifaController.text);

    tarifa ??= 0;
    if (peso != null) {
      setState(() {
        _precioSugerido = peso * tarifa!;
      });
    } else {
      setState(() => _precioSugerido = 0.0);
    }
  }

  Future<void> _cargarLocalidades() async {
    try {
      final localidades = await LocalidadService().fetchLocalidades();
      String? ciudadDelUsuario = userLocalidad.value!['nombre'].toString();
      setState(() {
        _listaNombresCiudades =
            localidades.map((l) => l['nombre'] as String).toList();
        for (var l in localidades) {
          _coordenadasCiudades[l['nombre']] = LatLng(
            (l['latitud'] as num).toDouble(),
            (l['longitud'] as num).toDouble(),
          );
          _mapaIdsCiudades[l['nombre']] = l['id'];
        }
        if (_listaNombresCiudades.contains(ciudadDelUsuario)) {
          _locOrigen = ciudadDelUsuario;
        }

        _cargandoLocalidades = false;
      });
    } catch (e) {
      print(e);
      AppService.showAlert("Error al cargar localidades");
      setState(() => _cargandoLocalidades = false);
    }
  }

  void _enviarSolicitud() {
    if (!_formKey.currentState!.validate()) return;

    if (_locOrigen == null ||
        _latLngOrigen == null ||
        _locDestino == null ||
        _latLngDestino == null) {
      AppService.showAlert(
        "Por favor, seleccioná los puntos exactos en el mapa",
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Por favor, seleccioná los puntos exactos en el mapa"),
      //   ),
      // );
      return;
    }

    final String? idOrigen = _mapaIdsCiudades[_locOrigen];
    final String? idDestino = _mapaIdsCiudades[_locDestino];

    AppService.runWithLoading(() async {
      try {
        final datos = {
          'origen_id': idOrigen,
          'origen_direccion': _dirOrigen,
          'origen_lat': _latLngOrigen!.latitude,
          'origen_lng': _latLngOrigen!.longitude,
          'destino_id': idDestino,
          'destino_direccion': _dirDestino,
          'destino_lat': _latLngDestino!.latitude,
          'destino_lng': _latLngDestino!.longitude,
          'descripcion': _descCtrl.text,
          'peso': double.tryParse(_pesoCtrl.text) ?? 0.0,
          'precio': double.tryParse(_tarifaController.text) ?? 0.0,
          'estado': 'PENDIENTE',
          'fecha_viaje': _fechaSeleccionada?.toIso8601String(),
        };
        await ViajesService().crearViaje(datos);

        AppService.showAlert("¡Viaje publicado con éxito!");
        if (mounted) {
          context.go('/mis-viajes'); // Redirige para que vea su lista
        }
      } catch (e) {
        print(e);
        AppService.showAlert("Error: No se pudo publicar el viaje");
      }
    });
  }

  void _abrirMapaPopup({required bool esOrigen}) async {
    final ciudadActual = esOrigen ? _locOrigen : _locDestino;
    final LatLng centro =
        _coordenadasCiudades[ciudadActual] ?? const LatLng(-34.9011, -56.1645);

    LatLng ubicacionTemporal = centro;
    final LatLng? resultado = await showDialog<LatLng>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Usamos un contexto específico para el diálogo
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox(
            width: 500,
            height: 500,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: centro,
                          zoom: 15,
                        ),
                        onCameraMove: (pos) => ubicacionTemporal = pos.target,
                        myLocationEnabled: true,
                      ),
                      // Pin fijo en el centro
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 35),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botonera inferior
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text("CANCELAR"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // USAMOS EL CONTEXTO DEL DIALOGO PARA CERRARLO
                          // Navigator.of(dialogContext).pop(ubicacionTemporal);
                          final posicionFinal = ubicacionTemporal;

                          // Cerramos el diálogo pasando el valor
                          Navigator.of(dialogContext).pop(posicionFinal);
                        },
                        child: const Text("CONFIRMAR"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 2. Al cerrar, procesamos la dirección si hubo resultado
    if (resultado != null) {
      final direccion = await GeocodingWebService.obtenerDireccion(resultado);
      setState(() {
        if (esOrigen) {
          _latLngOrigen = resultado;
          _dirOrigen = direccion;
        } else {
          _latLngDestino = resultado;
          _dirDestino = direccion;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Publicar Carga",
      icon: Icons.add_road_rounded,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child:
            _cargandoLocalidades
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  // Previene el error de RenderFlex
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ruta del Viaje",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 200,
                          child: TextFormField(
                            controller: _fechaController,
                            readOnly:
                                true, // Evita que el usuario escriba manualmente
                            decoration: const InputDecoration(
                              labelText: "Fecha del Viaje",
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                              hintText: "Seleccione el día",
                            ),
                            onTap: () => _seleccionarFecha(context),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor seleccione una fecha';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isMobile = constraints.maxWidth < 600;
                            return isMobile
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildRouteFields(),
                                )
                                : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildRouteFields(isRow: true),
                                );
                          },
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Detalles de la Carga",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildInput(
                          _descCtrl,
                          "Descripción de mercadería",
                          Icons.inventory_2,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const SizedBox(width: 200),
                            Expanded(
                              child: _buildInput(
                                _pesoCtrl,
                                "Peso Estimado (Toneladas)",
                                Icons.fitness_center,
                                isNumber: true,
                                // onChanged:
                                //     (_) =>
                                //         _calcularPrecio(), // Recalcula al escribir
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInput(
                                _tarifaController,
                                "Tarifa Carga (\$)",
                                Icons.fitness_center,
                                isNumber: true,
                                // onChanged:
                                //     (_) =>
                                //         _calcularPrecio(), // Recalcula al escribir
                              ),
                            ),
                            const SizedBox(width: 120),
                          ],
                        ),
                        if (_precioSugerido > 0)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Precio Sugerido",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Basado en ${double.tryParse(_tarifaController.text)} por tonelada",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "\$${_precioSugerido.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _enviarSolicitud,
                            icon: const Icon(Icons.send_rounded),
                            label: const Text("PUBLICAR SOLICITUD"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  List<Widget> _buildRouteFields({bool isRow = false}) {
    return [
      // --- ORIGEN ---
      isRow
          ? Expanded(child: _buildSeccionOrigen()) // En Row necesita Expanded
          : _buildSeccionOrigen(), // En Column no es obligatorio

      if (isRow) const SizedBox(width: 20) else const SizedBox(height: 20),

      // --- DESTINO ---
      isRow
          ? Expanded(child: _buildSeccionDestino()) // En Row necesita Expanded
          : _buildSeccionDestino(),
    ];
  }

  Widget _buildSeccionOrigen() {
    return _seccionUbicacion(
      esOrigen: true,
      titulo: "Origen",
      localidad: _locOrigen,
      direccion: _dirOrigen,
      onLocalidadChanged:
          (val) => setState(() {
            _locOrigen = val;
            _dirOrigen = null;
            _latLngOrigen = null;
          }),
      onMapaConfirmado:
          (latLng, calle) => setState(() {
            _latLngOrigen = latLng;
            _dirOrigen = calle;
          }),
    );
  }

  Widget _buildSeccionDestino() {
    return _seccionUbicacion(
      esOrigen: false,
      titulo: "Destino",
      localidad: _locDestino,
      direccion: _dirDestino,
      onLocalidadChanged:
          (val) => setState(() {
            _locDestino = val;
            _dirDestino = null;
            _latLngDestino = null;
          }),
      onMapaConfirmado:
          (latLng, calle) => setState(() {
            _latLngDestino = latLng;
            _dirDestino = calle;
          }),
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
      mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
      crossAxisAlignment: CrossAxisAlignment.start, //
      children: [
        Text(titulo, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // 1. Selector de Localidad (Simple)
        DropdownButtonFormField<String>(
          value: (_listaNombresCiudades.contains(localidad)) ? localidad : null,

          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: "Elegí la ciudad",
          ),
          // Aquí usas tu lista simple de ciudades desde Supabase
          items:
              _listaNombresCiudades
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
          onChanged: onLocalidadChanged,
        ),

        const SizedBox(height: 10),

        // 2. Selector de Punto Exacto (Solo si hay ciudad)
        if (localidad != null)
          InkWell(
            onTap: () async {
              _abrirMapaPopup(esOrigen: esOrigen);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: direccion == null ? Colors.grey : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      direccion ?? "Marcá el punto exacto en el mapa",
                      style: TextStyle(
                        color: direccion == null ? Colors.white : Colors.white,
                        fontSize: 14,
                        fontWeight:
                            direccion == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.map_outlined, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (v) => v!.isEmpty ? "Este campo es obligatorio" : null,
    );
  }
}
