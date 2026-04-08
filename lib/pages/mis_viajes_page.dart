import 'package:demos/services/app_state.dart';
import 'package:demos/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import '../widgets/page_layout.dart';

class MisViajesPage extends StatefulWidget {
  const MisViajesPage({super.key});

  @override
  State<MisViajesPage> createState() => _MisViajesPageState();
}

class _MisViajesPageState extends State<MisViajesPage> {
  final _viajesService = ViajesService();

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      title: "Mis Solicitudes de Viaje",
      icon: Icons.history,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _viajesService.fetchMisViajes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Aún no has publicado ningún viaje."),
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
    final String estado = viaje['estado'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // border: Border.all(color: Colors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRouteHeader(
                  viaje['origen']['nombre'],
                  viaje['destino']['nombre'],
                ),
                _buildStatusBadge(estado),
              ],
            ),
            const Divider(height: 30),
            _buildDetailsRow(viaje),
            if (estado == 'PENDIENTE') ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarCancelacion(context, viaje['id']),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("CANCELAR SOLICITUD"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
            if (viaje['transportista'] != null) ...[
              const SizedBox(height: 15),
              _buildTransportistaInfo(viaje['transportista']),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmarCancelacion(BuildContext context, String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("¿Cancelar solicitud?"),
            content: const Text(
              "Esta acción eliminará la publicación y los transportistas ya no podrán verla.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Volver"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(context);
                  AppService.runWithLoading(() async {
                    await _viajesService.cancelarViaje(id);
                    setState(() {}); // Refresca la lista
                    AppService.showAlert("Viaje cancelado correctamente");
                  });
                },
                child: const Text("Confirmar Cancelación"),
              ),
            ],
          ),
    );
  }

  Widget _buildRouteHeader(String origen, String destino) {
    return Row(
      children: [
        Text(origen, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward, size: 16, color: Colors.indigo),
        ),
        Text(destino, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String estado) {
    Color color = Colors.orange;
    if (estado == 'ACEPTADO') color = Colors.blue;
    if (estado == 'EN_VIAJE') color = Colors.purple;
    if (estado == 'FINALIZADO') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDetailsRow(Map<String, dynamic> viaje) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Carga: ${viaje['descripcion_carga']}",
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          "\$${viaje['precio_ofertado']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTransportistaInfo(Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 20, color: Colors.indigo),
          const SizedBox(width: 10),
          Text(
            "Asignado a: ${t['nombre']}",
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.phone, size: 18, color: Colors.green),
            onPressed: () {}, // Aquí podrías disparar el llamado o whatsapp
          ),
        ],
      ),
    );
  }
}
