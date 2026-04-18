import 'package:cargasuy/models/vehiculo.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/services/db/localidades_service.dart';
import 'package:cargasuy/services/db/transportista_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/page_layout.dart';
import '../services/app_state.dart';

class CargasDisponiblesPage extends StatefulWidget {
  const CargasDisponiblesPage({super.key});

  @override
  State<CargasDisponiblesPage> createState() => _CargasDisponiblesPageState();
}

class _CargasDisponiblesPageState extends State<CargasDisponiblesPage> {
  final _viajesService = ViajesService();
  final String _miId = Supabase.instance.client.auth.currentUser!.id;
  String? _filtroOrigen;
  String? _filtroDestino;
  double? _filtroPeso;
  // bool _usarRadioCercania = false;
  double _radioKm = 80.0;
  List<Map<String, dynamic>> _localidades = []; // Aquí guardaremos la lista
  String? _filtroOrigenId;
  double? _latOrigenFiltro;
  double? _lonOrigenFiltro;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  String? _filtroDestinoId;
  double? _latDestinoFiltro;
  double? _lonDestinoFiltro;
  bool _filtrarPorDestino = false;

  @override
  void initState() {
    super.initState();
    _cargarLocalidades();
  }

  Future<void> _cargarLocalidades() async {
    final datos = await LocalidadService().fetchLocalidades();
    setState(() {
      _localidades = datos;
    });
  }

  Widget _buildSimpleDropdown(
    String label,
    String? value,
    Function(String?) onChanged,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: LocalidadService().fetchLocalidades(),
      builder: (context, snapshot) {
        return DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text("Todas")),
            ...(snapshot.data ?? []).map(
              (loc) => DropdownMenuItem(
                value: loc['id'].toString(),
                child: Text(loc['nombre']),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildFiltroOrigen() {
    return DropdownButtonFormField<String>(
      value: _filtroOrigenId,
      decoration: const InputDecoration(
        labelText: "Origen",
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text("Todas las ciudades")),
        ..._localidades.map(
          (loc) => DropdownMenuItem(
            value: loc['id'].toString(),
            child: Text(loc['nombre']),
          ),
        ),
      ],
      onChanged: (val) {
        setState(() {
          _filtroOrigenId = val;
          if (val != null) {
            // Buscamos la ciudad elegida para sacar su latitud y longitud
            final loc = _localidades.firstWhere(
              (l) => l['id'].toString() == val,
            );
            _latOrigenFiltro = loc['latitud'];
            _lonOrigenFiltro = loc['longitud'];
          } else {
            _latOrigenFiltro = null;
            _lonOrigenFiltro = null;
          }
        });
      },
    );
  }

  Widget _buildFiltrosAvanzados() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildFiltros(),

            const SizedBox(height: 10),
            // FILTRO DE RADIO (Slider)
            Row(
              children: [
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Peso Máx (Ton)",
                      prefixIcon: Icon(Icons.scale),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() => _filtroPeso = double.tryParse(val));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.radar, color: Colors.indigo),
                const SizedBox(width: 10),
                Text("Radio: ${_radioKm.round()} km"),
                Expanded(
                  child: Slider(
                    value: _radioKm,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: "${_radioKm.round()} km",
                    onChanged: (val) => setState(() => _radioKm = val),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await showDatePicker(
                        locale: const Locale('es', 'ES'),
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (f != null) setState(() => _fechaDesde = f);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _fechaDesde == null
                          ? "Fecha Desde"
                          : "${_fechaDesde!.day}/${_fechaDesde!.month}",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await showDatePicker(
                        locale: const Locale('es', 'ES'),
                        context: context,
                        initialDate: _fechaDesde ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (f != null) setState(() => _fechaHasta = f);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _fechaHasta == null
                          ? "Fecha Hasta"
                          : "${_fechaHasta!.day}/${_fechaHasta!.month}",
                    ),
                  ),
                ),
                if (_fechaDesde != null || _fechaHasta != null)
                  IconButton(
                    onPressed:
                        () => setState(() {
                          _fechaDesde = null;
                          _fechaHasta = null;
                        }),
                    icon: const Icon(Icons.clear, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroDestino() {
    return DropdownButtonFormField<String>(
      value: _filtroDestinoId,
      decoration: const InputDecoration(
        labelText: "Destino",
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text("Todas las ciudades")),
        ..._localidades.map(
          (loc) => DropdownMenuItem(
            value: loc['id'].toString(),
            child: Text(loc['nombre']),
          ),
        ),
      ],
      onChanged: (val) {
        setState(() {
          _filtroDestinoId = val;
          if (val != null) {
            // Buscamos la ciudad elegida para sacar su latitud y longitud
            final loc = _localidades.firstWhere(
              (l) => l['id'].toString() == val,
            );
            _latDestinoFiltro = loc['latitud'];
            _lonDestinoFiltro = loc['longitud'];
          } else {
            _latDestinoFiltro = null;
            _lonDestinoFiltro = null;
          }
        });
      },
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        // Filtro Origen
        Expanded(child: _buildFiltroOrigen()),
        const SizedBox(width: 10),
        // Filtro Destino
        Expanded(child: _buildFiltroDestino()),
        // Botón Limpiar
        IconButton(
          onPressed:
              () => setState(() {
                _filtroOrigen = null;
                _filtroDestino = null;
              }),
          icon: const Icon(Icons.filter_alt_off, color: Colors.red),
          tooltip: "Limpiar filtros",
        ),
        const SizedBox(width: 20),
        Row(
          children: [
            const Text("Filtrar radio en: "),
            ChoiceChip(
              label: const Text("Origen"),
              selected: !_filtrarPorDestino,
              onSelected: (val) => setState(() => _filtrarPorDestino = false),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("Destino"),
              selected: _filtrarPorDestino,
              onSelected: (val) => setState(() => _filtrarPorDestino = true),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Buscar Cargas",
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _buildFiltrosAvanzados(),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _viajesService.fetchCargasCercanas(
                // Si filtramos por destino, mandamos lat/lon del destino, sino del origen
                lat:
                    _filtrarPorDestino
                        ? (_latDestinoFiltro ?? 0.0)
                        : (_latOrigenFiltro ?? 0.0),
                lon:
                    _filtrarPorDestino
                        ? (_lonDestinoFiltro ?? 0.0)
                        : (_lonOrigenFiltro ?? 0.0),
                radio: _radioKm,
                buscarEnDestino:
                    _filtrarPorDestino, // Le avisamos al SQL que busque en destino_id
                fechaInicio: _fechaDesde,
                fechaFin: _fechaHasta,
              ),
              builder: (context, snapshot) {
                // print(snapshot.data.toString());
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No hay cargas disponibles por el momento."),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final viaje = snapshot.data![index];
                    return _buildCargaCard(viaje);
                    // return _buildViajeCard(viaje);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargaCard(Map<String, dynamic> carga) {
    final bool soyElCreador = carga['creador_id'] == _miId;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => context.push('/detalle-viaje/${carga['id']}'),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABECERA: Precio y Categoría
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "💰 \$${carga['precio_ofertado']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                  ),
                  _buildBadge(carga['tipo_carga'] ?? 'General'),
                ],
              ),
              const SizedBox(height: 15),

              // CUERPO: Ruta (Origen -> Destino)
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${carga['origen']['nombre']} ➔ ${carga['destino']['nombre']}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    child: Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carga['creador']['nombre'] ?? 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        carga['creador']['mail'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Botón de contacto rápido
                  IconButton(
                    icon: const Icon(Icons.sms, color: Colors.green),
                    onPressed:
                        () => _contactarCliente(carga['creador']['celular']),
                  ),
                ],
              ),
              // DETALLES: Peso y Fecha
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallInfo(
                    Icons.monitor_weight_outlined,
                    "${carga['peso_estimado']} Ton.",
                  ),
                  _buildSmallInfo(
                    Icons.calendar_today_outlined,
                    carga['fecha_viaje'] ?? 'A convenir',
                  ),
                ],
              ),

              const Divider(height: 25),

              // PIE: Descripción corta
              Text(
                carga['descripcion_carga'] ?? "Sin descripción adicional",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 15),
              if (carga['estado'] == 'PENDIENTE' && !soyElCreador)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirModalAceptarCarga(context, carga),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("ACEPTAR ESTA CARGA"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else if (soyElCreador)
                const Chip(
                  label: Text("TU PUBLICACIÓN"),
                  backgroundColor: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadge(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Color de fondo suave
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _abrirModalAceptarCarga(
    BuildContext context,
    Map<String, dynamic> viaje,
  ) {
    String? vehiculoSeleccionadoId;
    final cliente = viaje['creador'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Aceptar y Asignar Unidad"),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECCIÓN 1: CONTACTO DEL CLIENTE
                    const Text(
                      "DATOS DEL CLIENTE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(cliente['nombre'] ?? 'Sin nombre'),
                      subtitle: Text(
                        "Tel: ${cliente['celular'] ?? 'No registrado'}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () => _contactarCliente(cliente['celular']),
                      ),
                    ),
                    const Divider(),

                    // SECCIÓN 2: SELECCIÓN DE VEHÍCULO
                    const SizedBox(height: 10),
                    const Text(
                      "ASIGNAR VEHÍCULO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Vehiculo>>(
                      future: TransportistaService().fetchMisVehiculos(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const LinearProgressIndicator();
                        if (snapshot.data!.isEmpty)
                          return const Text("⚠️ No tienes vehículos cargados.");

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Elegir Camión",
                          ),
                          items:
                              snapshot.data!
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v.id,
                                      child: Text("${v.patente} - ${v.modelo}"),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) => vehiculoSeleccionadoId = val,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (vehiculoSeleccionadoId == null) {
                    AppService.showAlert("Debes seleccionar un vehículo");
                    return;
                  }

                  Navigator.pop(context); // Cierra modal
                  AppService.runWithLoading(() async {
                    await _viajesService.aceptarYAsignarViaje(
                      viaje['id'],
                      vehiculoSeleccionadoId!,
                      viaje['creador_id'],
                    );
                    setState(() {}); // Refresca lista
                    AppService.showAlert("Viaje aceptado. ¡Buen viaje!");
                  });
                },
                child: const Text("CONFIRMAR Y ACEPTAR"),
              ),
            ],
          ),
    );
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    // Calculamos si es rentable (Ej: si el precio es mayor a $1500 por Ton)
    final double peso =
        double.tryParse(viaje['peso_estimado'].toString()) ?? 1.0;
    final double precio =
        double.tryParse(viaje['precio_ofertado'].toString()) ?? 0.0;
    final bool esRentable = (precio / peso) >= 1500;
    final bool soyElCreador = viaje['creador_id'] == _miId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRouteHeader(
                  viaje['origen']['nombre'],
                  viaje['destino']['nombre'],
                ),
                // BADGE DE RENTABILIDAD
                if (esRentable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "ALTA RENTABILIDAD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),

            // DATOS DEL CLIENTE
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viaje['creador']['nombre'] ?? 'Usuario',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      viaje['creador']['mail'],
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                // Botón de contacto rápido
                IconButton(
                  icon: const Icon(Icons.sms, color: Colors.green),
                  onPressed:
                      () => _contactarCliente(viaje['creador']['celular']),
                ),
              ],
            ),

            if (viaje['estado'] == 'PENDIENTE' && !soyElCreador)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirModalAceptarCarga(context, viaje),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("ACEPTAR ESTA CARGA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (soyElCreador)
              const Chip(
                label: Text("TU PUBLICACIÓN"),
                backgroundColor: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader(String origen, String destino) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Origen
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ORIGEN",
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              origen,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),

        // Icono de conexión
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.indigo,
            size: 20,
          ),
        ),

        // Destino
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "DESTINO",
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              destino,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _contactarCliente(String? celular) {
    if (celular == null) {
      AppService.showAlert("El cliente no registró celular");
      return;
    }
    // Aquí podrías usar url_launcher para abrir WhatsApp directamente
    AppService.showAlert("Llamando al cliente: $celular");
  }
}
