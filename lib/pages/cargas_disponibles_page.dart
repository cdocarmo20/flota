import 'package:demos/models/vehiculo.dart';
import 'package:demos/services/auth_service.dart';
import 'package:demos/services/db/localidades_service.dart';
import 'package:demos/services/db/transportista_service.dart';
import 'package:demos/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
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

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.indigo.withOpacity(0.05),
      child: Row(
        children: [
          // Filtro Origen
          Expanded(
            child: _buildSimpleDropdown("Origen", _filtroOrigen, (val) {
              setState(() => _filtroOrigen = val);
            }),
          ),
          const SizedBox(width: 10),
          // Filtro Destino
          Expanded(
            child: _buildSimpleDropdown("Destino", _filtroDestino, (val) {
              setState(() => _filtroDestino = val);
            }),
          ),
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
          Expanded(
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Marketplace y Mis Viajes",
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // Usamos la función que filtra según el rol que definimos antes
              // future: _viajesService.fetchViajesSegunRol(),
              future: _viajesService.fetchCargasFiltradas(
                origenId: _filtroOrigen,
                destinoId: _filtroDestino,
                pesoMaximo: _filtroPeso,
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

                    return _buildViajeCard(viaje);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _abrirModalAceptarCarga(
    BuildContext context,
    Map<String, dynamic> viaje,
  ) {
    String? vehiculoSeleccionadoId;
    final cliente = viaje['cliente'];

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

  void _mostrarSelectorVehiculo(
    BuildContext context,
    Map<String, dynamic> viaje,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.indigo),
                SizedBox(width: 10),
                Text("Asignar Vehículo"),
              ],
            ),
            content: SizedBox(
              width: 400,
              // Usamos el servicio para traer solo los vehículos del transportista logueado
              child: FutureBuilder<List<Vehiculo>>(
                future: TransportistaService().fetchMisVehiculos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No tienes vehículos registrados para asignar.",
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Selecciona la unidad que realizará el transporte:",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      // Lista de vehículos
                      ...snapshot.data!.map(
                        (v) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.badge_outlined),
                            title: Text(
                              v.patente,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("${v.modelo} - ${v.capacidad}"),
                            trailing: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.indigo,
                            ),
                            onTap: () {
                              Navigator.pop(context); // Cierra el modal
                              _confirmarAceptacionViaje(
                                viaje['id'],
                                v,
                              ); // Llama a la confirmación
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
            ],
          ),
    );
  }

  void _confirmarAceptacionViaje(String viajeId, Vehiculo vehiculo) {
    AppService.runWithLoading(() async {
      try {
        // 1. Llamamos al servicio para actualizar transportista_id, vehiculo_id y estado
        await _viajesService.asignarViajeAVehiculo(viajeId, vehiculo.id);

        // 2. Refrescamos la UI
        setState(() {});

        AppService.showAlert(
          "Viaje asignado con éxito al vehículo ${vehiculo.patente}",
        );
      } catch (e) {
        AppService.showAlert("Error al asignar el viaje: $e");
      }
    });
  }

  // --- MÉTODOS DE ACCIÓN ---

  Future<void> _cambiarEstadoViaje(
    String id,
    String nuevoEstado,
    String mensaje,
  ) async {
    AppService.runWithLoading(() async {
      await _viajesService.actualizarEstadoViaje(id, nuevoEstado);
      setState(() {}); // Refrescar la lista
      AppService.showAlert(mensaje);
    });
  }

  // --- COMPONENTES VISUALES ---

  Widget _buildActionButton(
    Map<String, dynamic> viaje,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final String estado = viaje['estado'];
    final String origenId = viaje['origen']['id'].toString();
    final String? miLocalidadId = userLocalidad.value?['id']?.toString();

    // VALIDACIÓN: Solo para "INICIAR VIAJE"
    bool bloqueadoPorUbicacion = false;
    if (estado == 'ACEPTADO' && miLocalidadId != origenId) {
      bloqueadoPorUbicacion = true;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            // Si está bloqueado, el botón no hace nada (onPressed: null)
            onPressed: bloqueadoPorUbicacion ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Text(label),
          ),
        ),
        if (bloqueadoPorUbicacion)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "⚠️ Debes estar en la localidad de origen para iniciar.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 45,
  //     child: ElevatedButton(
  //       onPressed: onTap,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: color,
  //         foregroundColor: Colors.white,
  //       ),
  //       child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  //     ),
  //   );
  // }

  Widget _buildStatusTag(String estado, bool esMio) {
    Color color = esMio ? Colors.green : Colors.orange;
    String texto = esMio ? "MI ASIGNACIÓN" : "DISPONIBLE";
    if (estado == 'EN_VIAJE') texto = "EN TRÁNSITO";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRouteInfo(String origen, String destino) {
    return Row(
      children: [
        Text(origen, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Icon(Icons.chevron_right, color: Colors.indigo),
        Text(destino, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCargoDetails(Map<String, dynamic> viaje) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${viaje['descripcion_carga']} (${viaje['peso_estimado']} Ton)",
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          "\$${viaje['precio_ofertado']}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
