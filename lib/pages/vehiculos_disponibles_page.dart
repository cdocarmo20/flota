import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/services/db/vehiculo_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehiculosDisponiblesPage extends StatefulWidget {
  const VehiculosDisponiblesPage({super.key});

  @override
  State<VehiculosDisponiblesPage> createState() => _VehiculosDisponiblesPage();
}

class _VehiculosDisponiblesPage extends State<VehiculosDisponiblesPage> {
  final _viajeService = ViajesService();

  // Variables de filtro
  String? _idOrigen;
  String? _idDestino;
  DateTime? _fechaFiltro;
  List<Map<String, dynamic>> _localidades = [];
  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;
  bool _estaCargando = false;
  @override
  void initState() {
    super.initState();
    _cargarLocalidades();
    _ejecutarBusqueda();
  }

  Future<void> _cargarLocalidades() async {
    final datos = await LocalidadService().fetchLocalidades();
    setState(() {
      _localidades = datos;
    });
  }

  void _ejecutarBusqueda() async {
    setState(() => _cargando = true);
    try {
      final res = await _viajeService.buscarViajes(
        idOrigen: _idOrigen,
        idDestino: _idDestino,
        fecha: _fechaFiltro,
      );
      setState(() => _resultados = res);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.grey[100],
  //     appBar: AppBar(
  //       title: const Text("Buscar Vehículos Disponibles"),
  //       elevation: 0,
  //     ),

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    Widget contenido = cargaDisponibleContent();
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text("Buscar Vehículos Disponibles")),
        body: contenido,
      );
    } else {
      return PageLayout(
        title: "Buscar Vehículos Disponibles",
        icon: Icons.local_mall,
        child: contenido,
      );
    }
  }

  Widget cargaDisponibleContent() {
    return Column(
      children: [
        _buildFiltros(), // Los campos que diseñamos arriba
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child:
                _cargando
                    ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(),
                    )
                    : _resultados.isEmpty
                    ? const Center(
                      key: ValueKey('empty'),
                      child: Text("No hay viajes con estos filtros"),
                    )
                    : ListView.builder(
                      key: ValueKey(
                        _resultados.length,
                      ), // Importante para la animación
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: _resultados.length,
                      itemBuilder:
                          (context, index) =>
                              _buildViajeCard(_resultados[index]),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                // ORIGEN
                Expanded(
                  child: _buildFiltroLocalidad(
                    label: "Origen",
                    icon: Icons.trip_origin,
                    selectedId: _idDestino,
                    onSelected: (id) {
                      _idOrigen = id.toString();
                      _ejecutarBusqueda();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // DESTINO
                Expanded(
                  child: _buildFiltroLocalidad(
                    label: "Destino",
                    icon: Icons.location_on,
                    selectedId: _idDestino,
                    onSelected: (id) {
                      _idDestino = id.toString();
                      _ejecutarBusqueda();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // FECHA Y LIMPIAR
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fechaFiltro == null
                                ? "Cualquier fecha"
                                : _formatearFecha(
                                  _fechaFiltro!.toIso8601String(),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_idOrigen != null ||
                    _idDestino != null ||
                    _fechaFiltro != null)
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list_off,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _idOrigen = null;
                        _idDestino = null;
                        _fechaFiltro = null;
                      });
                      _ejecutarBusqueda();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? seleccionado = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime.now(), // No permite elegir fechas pasadas
      lastDate: DateTime.now().add(
        const Duration(days: 90),
      ), // Máximo 3 meses a futuro
      helpText: 'Selecciona la fecha del viaje',
      confirmText: 'Filtrar',
      cancelText: 'Cancelar',
    );

    if (seleccionado != null && seleccionado != _fechaFiltro) {
      setState(() {
        _fechaFiltro = seleccionado;
      });
      _ejecutarBusqueda(); // Filtra automáticamente tras elegir
    }
  }

  Widget _buildFiltroLocalidad({
    required String label,
    required IconData icon,
    required String? selectedId,
    required Function(String?) onSelected,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Autocomplete<Map<String, dynamic>>(
        displayStringForOption: (option) => option['nombre'],

        // Optimizamos la búsqueda del valor inicial para evitar errores
        initialValue: TextEditingValue(
          text:
              selectedId != null
                  ? _localidades.firstWhere(
                    (l) => l['id'].toString() == selectedId,
                    orElse: () => {'nombre': ''},
                  )['nombre']
                  : '',
        ),

        optionsBuilder: (textValue) {
          if (textValue.text.isEmpty) return const Iterable.empty();
          final query = textValue.text.toLowerCase();
          return _localidades.where(
            (loc) => loc['nombre'].toString().toLowerCase().contains(query),
          );
        },

        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ), // Color actual
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              prefixIcon: Icon(
                label == "Origen" ? Icons.trip_origin : Icons.location_on,
                size: 20,
              ),
              border: const OutlineInputBorder(),
              suffixIcon:
                  controller.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          onSelected(null); // Notificamos el borrado
                        },
                      )
                      : null,
            ),
          );
        },

        optionsViewBuilder: (context, onSelectedOption, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 250,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      visualDensity: VisualDensity.compact,
                      title: Text(option['nombre']),
                      onTap: () => onSelectedOption(option),
                    );
                  },
                ),
              ),
            ),
          );
        },

        onSelected: (selection) => onSelected(selection['id'].toString()),
      ),
    );
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final esMiPropioViaje = viaje['creador_id'] == currentUser!.id;
    final String tipoCamion =
        viaje['vehiculo']['tipo_vehiculo']['nombre'] ?? 'No especificado';
    final perfil = viaje['creador'];
    final String nombreDuenio = perfil?['nombre'] ?? 'Usuario';
    final String telefono = perfil?['telefono'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Marca y Modelo del Vehículo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      "${viaje['vehiculo']['patente']} ${viaje['vehiculo']['modelo']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Aquí podrías mostrar un precio si lo tuvieras en tu tabla
                // const Text(
                //   "\$450",
                //   style: TextStyle(
                //     color: Colors.green,
                //     fontWeight: FontWeight.bold,
                //     fontSize: 18,
                //   ),
                // ),
              ],
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 12,
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreDuenio,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Dueño del vehículo",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón rápido de contacto
                if (telefono.isNotEmpty)
                  IconButton(
                    onPressed: () {}, // => _abrirWhatsApp(telefono),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.green,
                    ),
                    tooltip: "Contactar",
                  ),
              ],
            ),
            const Divider(height: 10),

            // Cuerpo: Ruta (Origen -> Destino)
            Row(
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      size: 18,
                      color: Colors.blue,
                    ),
                    Container(width: 2, height: 30, color: Colors.grey[300]),
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viaje['origen']['nombre'],
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        viaje['destino']['nombre'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pie: Fecha y Botón de Acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearFecha(viaje['fecha_disponibilidad']),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                _buildBadgeTipo(tipoCamion.toUpperCase()),
                if (!esMiPropioViaje && viaje['estado'] == 'ACTIVO')
                  ElevatedButton(
                    onPressed: () => _confirmarTomarViaje(viaje),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF2ECC71,
                      ), // Verde Esmeralda
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Tomar Viaje",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                // ElevatedButton(
                //   onPressed: () {
                //     // Acción para ver detalles o contactar
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.blueAccent,
                //     foregroundColor: Colors.white,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text("Ver Detalles"),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarTomarViaje(Map<String, dynamic> viaje) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "¿Confirmar este viaje?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Vas a tomar el viaje de ${viaje['origen']['nombre']} a ${viaje['destino']['nombre']}.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // Cierra el modal
                        await _procesarTomaDeViaje(viaje['id']);
                      },
                      child: const Text("Confirmar"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarTomaDeViaje(String viajeId) async {
    setState(() => _estaCargando = true);
    try {
      await _viajeService.tomarViaje(viajeId);

      AppService.showAlert("✅ ¡Viaje reservado con éxito!");
      // Refrescamos la lista para que el viaje ya no aparezca
      _ejecutarBusqueda();
    } catch (e) {
      AppService.showAlert("❌ Error: ${e.toString()}");
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  Widget _buildBadgeTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(
          0xFF2D3142,
        ), // Un gris azulado oscuro muy profesional
        borderRadius: BorderRadius.circular(4), // Bordes casi rectos
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        tipo.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // Función auxiliar para que la fecha se vea bien (Uruguay style)
  String _formatearFecha(String fechaIso) {
    final fecha = DateTime.parse(fechaIso);
    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }
}
