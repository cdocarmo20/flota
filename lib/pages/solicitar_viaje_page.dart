import 'package:demos/services/auth_service.dart';
import 'package:demos/services/db/localidades_service.dart';
import 'package:demos/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/page_layout.dart';

import '../services/app_state.dart';

class SolicitarViajePage extends StatefulWidget {
  const SolicitarViajePage({super.key});

  @override
  State<SolicitarViajePage> createState() => _SolicitarViajePageState();
}

class _SolicitarViajePageState extends State<SolicitarViajePage> {
  final _formKey = GlobalKey<FormState>();
  String? _origenId;
  String? _destinoId;
  final _descCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  double _precioSugerido = 0.0;
  double _tarifaPorTonelada = 1500.0; // Valor ejemplo (puedes cambiarlo)
  DateTime? _fechaSeleccionada;
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _tarifaController = TextEditingController();
  List<Map<String, dynamic>> _localidades = [];
  bool _isLoadingLoc = true;

  @override
  void initState() {
    super.initState();
    _cargarLocalidades().then((_) {
      // Si el usuario tiene una localidad guardada, la ponemos como origen por defecto
      if (userLocalidad.value != null) {
        setState(() {
          _origenId = userLocalidad.value!['id'].toString();
        });
      }
    });
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
        // Formateamos la fecha para mostrarla en el campo de texto
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
      final datos = await LocalidadService().fetchLocalidades();
      setState(() {
        _localidades = datos;
        _isLoadingLoc = false;
      });
    } catch (e) {
      AppService.showAlert("Error al cargar localidades");
      setState(() => _isLoadingLoc = false);
    }
  }

  void _enviarSolicitud() {
    if (!_formKey.currentState!.validate()) return;
    if (_origenId == _destinoId) {
      AppService.showAlert("Origen y Destino no pueden ser iguales");
      return;
    }
    // final datosViaje = {
    //   'origen_id': _origenId,
    //   'destino_id': _destinoId,
    //   'descripcion': _descCtrl.text,
    //   'peso': double.parse(_pesoCtrl.text),
    //   'precio': _precioSugerido, // Guardamos el precio calculado
    //   'estado': 'PENDIENTE',
    // };

    AppService.runWithLoading(() async {
      try {
        final datos = {
          'origen_id': _origenId,
          'destino_id': _destinoId,
          'descripcion': _descCtrl.text,
          'peso': double.tryParse(_pesoCtrl.text) ?? 0.0,
          'precio': _precioSugerido,
          'estado': 'PENDIENTE',
          'fecha_viaje': _fechaSeleccionada?.toIso8601String(),
        };

        await ViajesService().crearViaje(datos);

        AppService.showAlert("¡Viaje publicado con éxito!");
        if (mounted)
          context.go('/mis-viajes'); // Redirige para que vea su lista
      } catch (e) {
        AppService.showAlert("Error: No se pudo publicar el viaje");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Publicar Carga",
      icon: Icons.add_road_rounded,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child:
            _isLoadingLoc
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
                        // DISEÑO RESPONSIVO DE RUTA
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isMobile = constraints.maxWidth < 600;
                            return isMobile
                                ? Column(children: _buildRouteFields())
                                : Row(children: _buildRouteFields(isRow: true));
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
                                onChanged:
                                    (_) =>
                                        _calcularPrecio(), // Recalcula al escribir
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInput(
                                _tarifaController,
                                "Tarifa por Tonelada (\$)",
                                Icons.fitness_center,
                                isNumber: true,
                                onChanged:
                                    (_) =>
                                        _calcularPrecio(), // Recalcula al escribir
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
    final widgets = [
      Expanded(
        flex: isRow ? 1 : 0,
        child: _buildDropdown(
          "Origen",
          _origenId,
          (v) => setState(() => _origenId = v),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: isRow ? 0 : 10),
        child: Icon(
          isRow ? Icons.arrow_forward : Icons.arrow_downward,
          color: Colors.indigo,
        ),
      ),
      Expanded(
        flex: isRow ? 1 : 0,
        child: _buildDropdown(
          "Destino",
          _destinoId,
          (v) => setState(() => _destinoId = v),
        ),
      ),
    ];
    // Si no es Row, quitamos el Expanded para evitar errores
    return isRow
        ? widgets
        : widgets.map((w) => w is Expanded ? w.child : w).toList();
  }

  Widget _buildDropdown(
    String label,
    String? value,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.location_on_outlined),
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
      onChanged: onChanged,
      validator: (v) => v == null ? "Seleccione localidad" : null,
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
