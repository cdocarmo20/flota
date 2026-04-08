import 'package:demos/models/vehiculo.dart';
import 'package:demos/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Marketplace y Mis Viajes",
      icon: Icons.local_shipping_outlined,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        // Usamos la función que filtra según el rol que definimos antes
        future: _viajesService.fetchViajesSegunRol(),
        builder: (context, snapshot) {
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
    );
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    final bool esMiViaje = viaje['transportista_id'] == _miId;
    final String estado = viaje['estado'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: esMiViaje ? Colors.green.shade300 : Colors.grey.shade300,
          width: esMiViaje ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRouteInfo(
                  viaje['origen']['nombre'],
                  viaje['destino']['nombre'],
                ),
                _buildStatusTag(estado, esMiViaje),
              ],
            ),
            const Divider(height: 30),
            _buildCargoDetails(viaje),
            const SizedBox(height: 20),

            // LÓGICA DE BOTONES SEGÚN ESTADO
            if (estado == 'PENDIENTE')
              _buildActionButton(
                viaje,
                "ACEPTAR CARGA",
                Colors.indigo,
                () => _mostrarSelectorVehiculo(context, viaje),
              )
            else if (estado == 'ACEPTADO' && esMiViaje)
              _buildActionButton(
                viaje, // Pasamos el mapa del viaje
                "INICIAR VIAJE",
                Colors.green,
                () => _cambiarEstadoViaje(
                  viaje['id'],
                  'EN_VIAJE',
                  "¡Buen viaje!",
                ),
              )
            // else if (estado == 'ACEPTADO' && esMiViaje)
            //   _buildActionButton(
            //     "INICIAR VIAJE",
            //     Colors.green,
            //     () => _cambiarEstadoViaje(
            //       viaje['id'],
            //       'EN_VIAJE',
            //       "¡Buen viaje! El cliente ha sido notificado.",
            //     ),
            //   )
            else if (estado == 'EN_VIAJE' && esMiViaje)
              _buildActionButton(
                viaje,
                "FINALIZAR ENTREGA",
                Colors.purple,
                () => _cambiarEstadoViaje(
                  viaje['id'],
                  'FINALIZADO',
                  "Viaje completado con éxito.",
                ),
              ),
          ],
        ),
      ),
    );
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
