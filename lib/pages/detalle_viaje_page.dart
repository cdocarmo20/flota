import 'package:cargasuy/models/vehiculo.dart';
import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/db/transportista_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/widgets/utilita_widgets.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong2.dart';
// import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart'; // 1. Importa esto
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// Ajusta la ruta a tu proyecto

class DetalleViajePage extends StatefulWidget {
  final String viajeId;

  const DetalleViajePage({super.key, required this.viajeId});

  @override
  State<DetalleViajePage> createState() => _DetalleViajePageState();
}

class _DetalleViajePageState extends State<DetalleViajePage> {
  final _viajesService = ViajesService();
  Map<String, dynamic>? _viaje;
  bool _loading = true;
  String? _error;
  bool esCliente = false;
  bool esTransportista = false;
  bool soyElTransportistaDeEsteViaje = false;
  bool soyElClienteDeEsteViaje = false;
  var userId = Supabase.instance.client.auth.currentUser?.id;
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // var userId = Supabase.instance.client.auth.currentUser?.id;
    final currentUser = Supabase.instance.client.auth.currentUser;
    // print(userId);
    if (widget.viajeId == 'null' || widget.viajeId.isEmpty) {
      setState(() {
        _error = "ID de viaje no válido";
        _loading = false;
      });
      return;
    }

    try {
      final data = await _viajesService.obtenerDetalleViaje(widget.viajeId);
      // print(data);
      setState(() {
        _viaje = data;

        soyElTransportistaDeEsteViaje =
            (currentUser?.id == data['transportista_id']);
        soyElClienteDeEsteViaje = (currentUser?.id == data['creador_id']);

        // esCliente = (userId == data['creador_id']);
        // esTransportista = (userId == data['transportista_id']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "No se pudo cargar el detalle del viaje";
        _loading = false;
      });
    }
  }

  Future<void> _finalizarViaje() async {
    setState(() => _loading = true);
    try {
      await _viajesService.procesarFinalizacionViaje(
        viajeId: widget.viajeId,
        creadorId: _viaje!['creador_id'],
        nombreTransportista: _viaje!['transportista']['nombre'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ ¡Entrega confirmada con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos(); // Recarga para actualizar estado y ocultar botón
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al finalizar: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _ajustarCamara(GoogleMapController controller, dynamic viaje) {
    LatLng origen = LatLng(viaje['origen_lat'], viaje['origen_lng']);
    LatLng destino = LatLng(viaje['destino_lat'], viaje['destino_lng']);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        origen.latitude < destino.latitude ? origen.latitude : destino.latitude,
        origen.longitude < destino.longitude
            ? origen.longitude
            : destino.longitude,
      ),
      northeast: LatLng(
        origen.latitude > destino.latitude ? origen.latitude : destino.latitude,
        origen.longitude > destino.longitude
            ? origen.longitude
            : destino.longitude,
      ),
    );

    // Le damos un "padding" de 50 para que los pines no queden pegados al borde
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null || _viaje == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? "Error desconocido")),
      );
    }

    final v = _viaje!;
    final fecha = DateTime.parse(v['fecha_viaje']);

    // Coordenadas para el mapa (con fallback por si son nulas)
    final latOri = v['origen']['latitud'] ?? -34.9011;
    final lonOri = v['origen']['longitud'] ?? -56.1645;
    final latDes = v['destino']['latitud'] ?? -31.3994;
    final lonDes = v['destino']['longitud'] ?? -57.9625;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Viaje"),
        backgroundColor: Colors.deepOrangeAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. MAPA INTERACTIVO
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: SizedBox(
                height: 250, // Altura del mapa
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(v['origen_lat'], v['origen_lng']),
                    zoom: 12,
                  ),
                  // Deshabilitamos el movimiento para que no moleste al hacer scroll en la página
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('origen'),
                      position: LatLng(v['origen_lat'], v['origen_lng']),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow: const InfoWindow(title: "Origen"),
                    ),
                    Marker(
                      markerId: const MarkerId('destino'),
                      position: LatLng(v['destino_lat'], v['destino_lng']),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: const InfoWindow(title: "Destino"),
                    ),
                  },
                  onMapCreated: (controller) {
                    // Ajustamos la cámara para que se vean AMBOS puntos automáticamente
                    _ajustarCamara(controller, v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. ESTADO Y FECHA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(v['estado']),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // 3. RUTA
                  _buildSectionTitle("Itinerario"),
                  _buildInfoTile(
                    Icons.circle,
                    Colors.blue,
                    "Origen",
                    v['origen']['nombre'],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['origen']['nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          v['origen_direccion'] ?? "Dirección no especificada",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  _buildInfoTile(
                    Icons.location_on,
                    Colors.red,
                    "Destino",
                    v['destino']['nombre'],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['destino']['nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          v['destino_direccion'] ?? "Dirección no especificada",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (v!['estado'] != 'PENDIENTE' &&
                      v!['transportista'] != null) ...[
                    _buildSectionTitle("Transportista Asignado"),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          v!['transportista']['nombre'] ?? "Sin nombre",
                        ),
                        subtitle: Text(
                          "Tel: ${v!['transportista']['telefono'] ?? "N/A"}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {},
                          // => launchUrl(
                          //   Uri.parse(
                          //     "tel:${v!['transportista']['telefono']}",
                          //   ),
                          // ),
                        ),
                      ),
                    ),
                  ] else if (v!['estado'] == 'PENDIENTE') ...[
                    // Mensaje amigable si aún no hay nadie
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "⏳ Buscando el mejor transportista disponible...",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (v!['vehiculo'] != null) ...[
                    _buildSectionTitle("Vehículo"),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: Text(
                          "${v!['vehiculo']['marca'] ?? ''} ${v!['vehiculo']['modelo'] ?? ''}",
                        ),
                        subtitle: Text(
                          "Matrícula: ${v!['vehiculo']['patente'] ?? 'S/D'}",
                        ),
                      ),
                    ),
                  ],
                  // 4. VEHÍCULO
                  // _buildSectionTitle("Vehículo"),
                  // Card(
                  //   child: ListTile(
                  //     leading: const Icon(
                  //       Icons.local_shipping,
                  //       color: Colors.blueGrey,
                  //     ),
                  //     title: Text("${v['vehiculo']['modelo']}"),
                  //     subtitle: Text("Patente: ${v['vehiculo']['patente']}"),
                  //   ),
                  // ),

                  // 5. CARGA Y CLIENTE
                  _buildSectionTitle("Información de Carga"),
                  _buildDetailRow("Descripción", v['descripcion_carga']),
                  _buildDetailRow("Peso", "${v['peso_estimado']} kg"),

                  // _buildDetailRow(
                  //   "Transportista",
                  //   v['transportista']['nombre'],
                  // ),
                  const SizedBox(height: 30),
                  if (v['resenia'] != null && v['resenia'].isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle("Calificación del Servicio"),
                    Card(
                      color: Colors.amber.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.amber, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Generamos las estrellas según el puntaje guardado
                                ...List.generate(
                                  5,
                                  (index) => Icon(
                                    index < v['resenia'][0]['estrellas']
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "Puntaje: ${v['resenia'][0]['estrellas']}/5",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              v['resenia'][0]['comentario'] ??
                                  "Sin comentarios adicionales",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (v['estado'] == 'PENDIENTE' && !soyElClienteDeEsteViaje)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _abrirModalAceptarCarga(context, v),
                        child: const Text(
                          "ACEPTAR ESTE VIAJE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  if (v['estado'] == 'ACEPTADO' &&
                      soyElTransportistaDeEsteViaje)
                    UtilitaWidgets().buildBotonAccion(
                      label: "MARCAR COMO ENTREGADO",
                      color: Colors.green,
                      icon: Icons.local_shipping,
                      onPressed: () async {
                        await _viajesService.finalizarViaje(
                          v['id'],
                          v['creador_id'].toString(),
                          v['origen']['nombre'],
                          v['destino']['nombre'],
                        );
                        _cargarDatos();
                      },
                    )
                  // CASO B: El cliente debe dar la CONFIRMACIÓN final
                  else if (v['estado'] == 'FINALIZADO' &&
                      soyElClienteDeEsteViaje)
                    Column(
                      children: [
                        const Text(
                          "¿Recibiste tu carga correctamente?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        UtilitaWidgets().buildBotonAccion(
                          label: "CONFIRMAR RECEPCIÓN",
                          color: Colors.blue,
                          icon: Icons.verified_user,
                          onPressed: () async {
                            await _viajesService.cambiarEstadoViaje(
                              v['id'],
                              'CONFIRMADO',
                            );
                            _cargarDatos();
                            _mostrarDialogoResenia();
                          },
                        ),
                      ],
                    )
                  // CASO C: Ya está todo cerrado
                  else if (v['estado'] == 'CONFIRMADO')
                    UtilitaWidgets().buildStatusBadge(
                      "VIAJE CERRADO Y CONFIRMADO",
                      Colors.blueGrey,
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalAceptarCarga(
    BuildContext context,
    Map<String, dynamic> viaje,
  ) {
    String? vehiculoSeleccionadoId;
    print(viaje);
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
                    // setState(() {}); // Refresca lista
                    AppService.showAlert("Viaje aceptado. ¡Buen viaje!");
                    _cargarDatos();
                  });
                },
                child: const Text("CONFIRMAR Y ACEPTAR"),
              ),
            ],
          ),
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

  void _mostrarDialogoResenia() {
    int estrellasSeleccionadas = 5; // Valor inicial
    final TextEditingController _comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // El StatefulBuilder es la clave para que las estrellas cambien al tocar
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Calificar transportista"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("¿Qué tal fue el servicio?"),
                  const SizedBox(height: 15),
                  // FILA DE ESTRELLAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        // Si el índice es menor a las estrellas seleccionadas, se pinta
                        icon: Icon(
                          index < estrellasSeleccionadas
                              ? Icons.star
                              : Icons.star_border,
                          color:
                              index < estrellasSeleccionadas
                                  ? Colors.amber
                                  : Colors.grey,
                        ),
                        onPressed: () {
                          // Usamos setDialogState para refrescar SOLO el diálogo
                          setDialogState(() {
                            estrellasSeleccionadas = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: _comentarioController,
                    decoration: const InputDecoration(
                      hintText: "Escribe un comentario (opcional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCELAR"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                  ),
                  onPressed: () async {
                    // Lógica para enviar a Supabase
                    await _viajesService.enviarResenia(
                      viajeId: widget.viajeId,
                      receptorId: _viaje!['transportista_id'],
                      emisorId: userId!,
                      estrellas: estrellasSeleccionadas,
                      comentario: _comentarioController.text,
                    );
                    Navigator.pop(context); // Cierra el diálogo
                    _cargarDatos(); // Refresca la pantalla principal
                  },
                  child: const Text(
                    "ENVIAR",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    Color color,
    String label,
    String value,
    Widget content,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: content,
      // subtitle: Text(
      //   value,
      //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      // ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildBadge(String estado) {
    Color color = estado == 'FINALIZADO' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _mostrarDialogoConfirmar() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("¿Carga entregada?"),
            content: const Text(
              "Confirmarás que la mercadería llegó a destino y se notificará al cliente.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _finalizarViaje();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("CONFIRMAR"),
              ),
            ],
          ),
    );
  }
}

// import 'package:cargasuy/services/db/viajes_service.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class DetalleViajePage extends StatefulWidget {
//   final String viajeId;

//   const DetalleViajePage({super.key, required this.viajeId});

//   @override
//   State<DetalleViajePage> createState() => _DetalleViajePageState();
// }

// class _DetalleViajePageState extends State<DetalleViajePage> {
//   bool _loading = true;
//   Map<String, dynamic>? _viaje;

//   @override
//   void initState() {
//     super.initState();
//     _cargarDetalles();
//   }

//   Future<void> _cargarDetalles() async {
//     try {
//       // Llamamos al servicio en lugar de hacer la consulta acá
//       final data = await ViajesService().obtenerDetalleViaje(widget.viajeId);

//       setState(() {
//         _viaje = data;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() => _loading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al cargar detalles: $e")));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading)
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));

//     if (_viaje == null) {
//       return const Scaffold(
//         body: Center(child: Text("No se encontró la información del viaje")),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Detalle de Carga"),
//         backgroundColor: Colors.deepOrangeAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ESTADO DEL VIAJE
//             _buildStatusCard(_viaje!['estado']),
//             const SizedBox(height: 20),

//             // RUTA (ORIGEN -> DESTINO)
//             _buildInfoCard(
//               title: "Trayecto",
//               icon: Icons.route,
//               content:
//                   "${_viaje!['origen']['nombre']} ➔ ${_viaje!['destino']['nombre']}",
//             ),

//             // INFORMACIÓN DE CARGA
//             _buildInfoCard(
//               title: "Detalles de Carga",
//               icon: Icons.inventory_2_outlined,
//               content:
//                   "Descripción: ${_viaje!['descripcion_carga']}\nPeso: ${_viaje!['peso']} kg",
//             ),

//             // CLIENTE / CONTACTO
//             _buildInfoCard(
//               title: "Cliente",
//               icon: Icons.person_outline,
//               content:
//                   "Nombre: ${_viaje!['transportista']['nombre']}\nTel: ${_viaje!['transportista']['telefono']}",
//               trailing: IconButton(
//                 icon: const Icon(Icons.message, color: Colors.green),
//                 onPressed: () {
//                   // Aquí conectaremos luego el WhatsApp
//                 },
//               ),
//             ),
//             const SizedBox(height: 30),

//             // BOTÓN FINALIZAR (Solo si está aceptado)
//             if (_viaje!['estado'] == 'ACEPTADO')
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   onPressed: () => _confirmarFinalizacion(context),
//                   icon: const Icon(Icons.check_circle_outline),
//                   label: const Text(
//                     "FINALIZAR ENTREGA",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _confirmarFinalizacion(BuildContext context) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text("¿Confirmar entrega?"),
//             content: const Text(
//               "Se notificará al cliente que la carga ha llegado a su destino.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("CANCELAR"),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _finalizarViaje();
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                 child: const Text("SÍ, FINALIZAR"),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> _finalizarViaje() async {
//     setState(() => _loading = true);
//     try {
//       // Llamamos al servicio pasando los datos que ya tenemos cargados en _viaje
//       await ViajesService().procesarFinalizacionViaje(
//         viajeId: widget.viajeId,
//         creadorId: _viaje!['creador_id'],
//         nombreTransportista: _viaje!['transportista']['nombre'],
//       );

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("✅ ¡Carga entregada con éxito!"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         _cargarDetalles(); // Refrescamos la UI
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
//         );
//         setState(() => _loading = false);
//       }
//     }
//   }

//   Widget _buildStatusCard(String estado) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.orange.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.orange),
//       ),
//       child: Center(
//         child: Text(
//           estado.toUpperCase(),
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.orange,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard({
//     required String title,
//     required IconData icon,
//     required String content,
//     Widget? trailing,
//   }) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 15),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.deepOrangeAccent),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(content),
//         trailing: trailing,
//       ),
//     );
//   }
// }
