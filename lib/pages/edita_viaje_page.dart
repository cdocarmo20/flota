import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:cargasuy/widgets/utilita_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EditarViajePage extends StatefulWidget {
  final Map<String, dynamic> viaje; // Pasamos los datos del viaje seleccionado

  const EditarViajePage({super.key, required this.viaje});

  @override
  State<EditarViajePage> createState() => _EditarViajePageState();
}

class _EditarViajePageState extends State<EditarViajePage> {
  late TextEditingController _pesoCtrl;
  late TextEditingController _tarifaCtrl;
  List<Map<String, dynamic>> _localidades = [];
  late TextEditingController _descripcionCtrl;
  late TextEditingController _precioCtrl;
  TextEditingController _fechaController = TextEditingController();
  String? _origenId;
  String? _destinoId;
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    // Mapeamos tus campos de Supabase a los controladores
    _descripcionCtrl = TextEditingController(
      text: widget.viaje['descripcion_carga'],
    );
    _pesoCtrl = TextEditingController(
      text: widget.viaje['peso_estimado'].toString(),
    );
    _precioCtrl = TextEditingController(
      text: widget.viaje['precio_ofertado'].toString(),
    );

    // Guardamos los UUID de origen y destino
    _origenId = widget.viaje['origen_id'];
    _destinoId = widget.viaje['destino_id'];

    if (widget.viaje['fecha_viaje'] != null) {
      _fechaController = TextEditingController(
        text: DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(widget.viaje['fecha_viaje'])),
        // DateTime.parse(widget.viaje['fecha_viaje']).toString(),
      );

      // _fechaController = DateTime.parse(widget.viaje['fecha_viaje']);
    }
    _cargarLocalidades();
  }

  Future<void> _cargarLocalidades() async {
    final datos = await LocalidadService().fetchLocalidades();
    setState(() {
      _localidades = datos;
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

  void _guardarCambios() async {
    // 1. Mostrar snackbar de "Procesando"
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(const SnackBar(content: Text("Actualizando carga...")));

    try {
      await ViajesService().actualizarViaje(
        viajeId: widget.viaje['id'].toString(),
        descripcion: _descripcionCtrl.text,
        peso: double.tryParse(_pesoCtrl.text) ?? 0.0,
        precio: double.tryParse(_precioCtrl.text) ?? 0.0,
        origenId: _origenId!,
        destinoId: _destinoId!,
        fechaViaje: _fechaSeleccionada,
      );

      // 2. Éxito y volver
      if (mounted) {
        AppService.showAlert("✅ Carga actualizada con éxito!");

        // ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("✅ Carga actualizada con éxito"),
        //     backgroundColor: Colors.green,
        //   ),
        // );
        context.pop();
        // Navigator.pop(
        //   context,
        //   true,
        // ); // Retornamos 'true' para avisar que hubo cambios
      }
    } catch (e) {
      if (mounted) {
        AppService.showAlert("No pudimos modificar el Viaje!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Editar Carga",
      icon: Icons.local_shipping_outlined,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _fechaController,
                readOnly: true, // Evita que el usuario escriba manualmente
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),

            UtilitaWidgets().buildInput(
              _descripcionCtrl,
              "Descripción de mercadería",
              Icons.inventory_2,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 200),
                Expanded(
                  child: UtilitaWidgets().buildInput(
                    _pesoCtrl,
                    "Peso Estimado (Toneladas)",
                    Icons.fitness_center,
                    isNumber: true,
                    // onChanged:
                    //     (_) => _calcularPrecio(), // Recalcula al escribir
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: UtilitaWidgets().buildInput(
                    _precioCtrl,
                    "Tarifa Carga (\$)",
                    Icons.fitness_center,
                    isNumber: true,
                    //   onChanged:
                    //       (_) => _calcularPrecio(), // Recalcula al escribir
                  ),
                ),
                const SizedBox(width: 120),
              ],
            ),

            // _buildFechaSelector(),
            // UtilitaWidgets().buildDropdownLocalidad(
            //   "Ciudad de Origen",
            //   _idOrigen,
            //   _localidades,
            //   (val) {
            //     setState(() => _idOrigen = val);
            //   },
            // ),

            // // Selector de DESTINO
            // UtilitaWidgets().buildDropdownLocalidad(
            //   "Ciudad de Destino",
            //   _idDestino,
            //   _localidades,
            //   (val) {
            //     setState(() => _idDestino = val);
            //   },
            // ),

            // const SizedBox(height: 10),
            // UtilitaWidgets().buildInput(
            //   _descripcionCtrl,
            //   "Descripción de la carga",
            //   Icons.description,
            // ),
            // Row(
            //   children: [
            //     Expanded(
            //       child: UtilitaWidgets().buildInput(
            //         _pesoCtrl,
            //         "Peso Estimado",
            //         Icons.fitness_center,
            //         isNumber: true,
            //       ),
            //     ),
            //     Expanded(
            //       child: UtilitaWidgets().buildInput(
            //         _precioCtrl,
            //         "Precio Ofertado (\$)",
            //         Icons.monetization_on,
            //         isNumber: true,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 20),
            Center(
              // Centra el bloque de botones horizontalmente
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ), // Ancho máximo de los botones
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BOTÓN CANCELAR (Más discreto)
                      Expanded(
                        child: SizedBox(
                          height: 45, // Un poco más bajo
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "CANCELAR",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // BOTÓN GUARDAR (Llamativo pero compacto)
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrangeAccent,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _guardarCambios(),
                            child: const Text(
                              "GUARDAR",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildFechaSelector() {
    return InkWell(
      onTap: () => _seleccionarFecha(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.indigo),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fecha del Viaje",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _fechaSeleccionada == null
                      ? "Seleccionar fecha"
                      : "${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
