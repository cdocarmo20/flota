import 'package:demos/models/transportista.dart';
import 'package:demos/models/vehiculo.dart';
import 'package:demos/services/logistica_service.dart';
import 'package:demos/widgets/comparador_flota.dart';
import 'package:demos/widgets/flota_chart.dart';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../widgets/status_chart.dart'; // Tu gráfico de pastel

// final List<Transportista> _listaTransportistas = [
//   Transportista(
//     nombre: "Logística Juan",
//     vehiculos: [
//       Vehiculo(
//         patente: "AAA",
//         modelo: "2022",
//         capacidad: "20 Ton",
//         tipo: "Sider",
//       ),
//       Vehiculo(
//         patente: "BBB",
//         modelo: "2021",
//         capacidad: "10 Ton",
//         tipo: "Furgón",
//       ),
//     ],
//     razonSocial: "Juan SA",
//     direccion: "Calle 1",
//     telefono: "123",
//     observaciones: "",
//   ),
//   Transportista(
//     nombre: "Transportes Express",
//     vehiculos: [
//       Vehiculo(
//         patente: "CCC",
//         modelo: "2023",
//         capacidad: "45 Ton",
//         tipo: "Playo",
//       ),
//     ],
//     razonSocial: "Express SRL",
//     direccion: "Calle 2",
//     telefono: "456",
//     observaciones: "",
//   ),
// ];

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Panel de Control",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 1. GRID DE MÉTRICAS (Resumen rápido)
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount:
                      constraints.maxWidth > 1200
                          ? 4
                          : (constraints.maxWidth > 800 ? 2 : 1),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.5,
                  children: [
                    _metricCard(
                      "Ventas Totales",
                      "\$12,450",
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _metricCard(
                      "Nuevos Clientes",
                      "48",
                      Icons.person_add,
                      Colors.blue,
                    ),
                    _metricCard(
                      "Pedidos Pendientes",
                      "12",
                      Icons.shopping_bag,
                      Colors.orange,
                    ),
                    _metricCard(
                      "Tasa de Conversión",
                      "3.5%",
                      Icons.trending_up,
                      Colors.purple,
                    ),
                  ],
                );
              },
            ),
            // buildComparador(_listaTransportistas[0], _listaTransportistas[1]),
            const SizedBox(height: 32),

            // 2. SECCIÓN DE GRÁFICOS Y ACCIONES
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expanded(child: _buildSeccionFlota(context)),
                // Gráfico de pastel (Status de Clientes)
                Expanded(
                  flex: 2,
                  child: _cardWrapper(
                    title: "Estado de Clientes",
                    child: const SizedBox(
                      height: 300,
                      child: StatusPieChart(activos: 15, pendientes: 5),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Botones de acción rápida
                Expanded(
                  flex: 1,
                  child: _cardWrapper(
                    title: "Acciones Rápidas",
                    child: Column(
                      children: [
                        _actionButton("Refrescar Datos", Icons.refresh, () {
                          AppService.runWithLoading(
                            () async => await Future.delayed(
                              const Duration(seconds: 2),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        _actionButton("Enviar Reporte", Icons.send, () {
                          AppService.showAlert(
                            "Reporte enviado al administrador",
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSeccionFlota(BuildContext context) {
  //   // 1. Calculamos los datos usando el servicio
  //   final Map<String, double> datosFlota =
  //       LogisticaService.calcularCapacidadPorTransportista(
  //         _listaTransportistas,
  //       );

  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).cardColor,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           "Capacidad de Carga por Empresa (Toneladas)",
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //         ),
  //         const SizedBox(height: 30),

  //         // 2. IMPORTANTE: Validar si hay datos para evitar errores de fl_chart
  //         if (datosFlota.isEmpty)
  //           const Center(child: Text("No hay datos de flota disponibles"))
  //         else
  //           SizedBox(
  //             height: 250, // Altura definida para que el gráfico no de error
  //             child: FlotaChart(datos: datosFlota),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // Widget para las tarjetas de métricas
  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Contenedor blanco para secciones más grandes
  Widget _cardWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white10, // Se adapta al modo oscuro/claro sutilmente
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
