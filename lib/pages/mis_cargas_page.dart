import 'package:demos/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import '../services/db/viajes_service.dart';

class MisCargasPage extends StatelessWidget {
  const MisCargasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageLayout(
      icon: Icons.alternate_email,
      title: 'Mis Solicitudes de Carga',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: ViajesService().obtenerMisCargasSolicitadas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error al cargar datos: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No has creado ninguna solicitud aún."),
            );
          }

          final cargas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cargas.length,
            itemBuilder: (context, index) {
              final carga = cargas[index];
              final String estado = carga['estado'] ?? 'PENDIENTE';
              final transportista = carga['transportista'];
              return Card(
                elevation: 2,
                child: ExpansionTile(
                  title: Text(
                    "${carga['origen']['nombre']} ➔ ${carga['destino']['nombre']}",
                  ),
                  subtitle: Text(
                    "Viaje: ${carga['fecha_viaje'] ?? 'Fecha a convenir'}",
                  ),
                  trailing: _buildBadgeEstado(estado),
                  children: [
                    if (estado == 'ACEPTADO' && transportista != null)
                      ListTile(
                        tileColor: Colors.blue.withOpacity(0.05),
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(
                          "Transportista: ${transportista['nombre']}",
                        ),
                        subtitle: Text("Tel: ${transportista['telefono']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.message, color: Colors.green),
                          onPressed: () {
                            // Lógica para contactar
                          },
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Buscando transportistas cercanos...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadgeEstado(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: estado == 'ACEPTADO' ? Colors.green : Colors.orange,
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

  Color _getColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACEPTADO':
        return Colors.blue;
      case 'EN CURSO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
