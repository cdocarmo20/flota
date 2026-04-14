import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
// import '../services/viajes_service.dart'; // Ajusta a tu ruta

class MisViajesAceptadosPage extends StatefulWidget {
  const MisViajesAceptadosPage({super.key});

  @override
  State<MisViajesAceptadosPage> createState() =>
      _MisViajesTransportistaPageState();
}

class _MisViajesTransportistaPageState extends State<MisViajesAceptadosPage>
    with SingleTickerProviderStateMixin {
  final _viajesService = ViajesService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _todosLosViajes = [];
  String? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _cargarViajes();
  }

  Future<void> _cargarViajes() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);

    try {
      // Obtenemos todos los viajes donde el usuario es el transportista
      final data = await _viajesService.obtenerMisViajesTransportista(_userId!);
      setState(() {
        _todosLosViajes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar viajes: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PageLayout(
        icon: Icons.alternate_email,
        title: 'Mis Cargas Aceptadas',
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: "EN CURSO", icon: Icon(Icons.local_shipping)),
                Tab(text: "HISTORIAL", icon: Icon(Icons.check_circle)),
              ],
            ),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Solapa 1: Viajes Aceptados o Finalizados (esperando confirmación cliente)
                      _buildListaFiltrada(['ACEPTADO', 'FINALIZADO']),

                      // Solapa 2: Viajes ya confirmados por el cliente
                      _buildListaFiltrada(['CONFIRMADO']),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaFiltrada(List<String> estados) {
    final lista =
        _todosLosViajes.where((v) => estados.contains(v['estado'])).toList();

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "No hay viajes en esta categoría",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarViajes,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final viaje = lista[index];
          return _buildCardViaje(viaje);
        },
      ),
    );
  }

  Widget _buildCardViaje(Map<String, dynamic> viaje) {
    final bool esConfirmado = viaje['estado'] == 'CONFIRMADO';
    final Color colorEstado = esConfirmado ? Colors.green : Colors.orange;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorEstado.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorEstado.withOpacity(0.1),
          child: Icon(
            esConfirmado ? Icons.done_all : Icons.more_horiz,
            color: colorEstado,
          ),
        ),
        title: Text(
          "${viaje['origen']['nombre']} ➔ ${viaje['destino']['nombre']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Fecha: ${viaje['fecha_viaje'] ?? 'A convenir'}"),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                viaje['estado'],
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          // Navegamos al detalle y refrescamos al volver por si cambió el estado
          await context.push('/detalle-viaje/${viaje['id']}');
          _cargarViajes();
        },
      ),
    );
  }
}

// import 'package:cargasuy/services/app_state.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../services/db/viajes_service.dart';
// import '../widgets/page_layout.dart';
// import 'package:url_launcher/url_launcher.dart'; // Para llamar al cliente

// class MisViajesAceptadosPage extends StatefulWidget {
//   const MisViajesAceptadosPage({super.key});

//   @override
//   State<MisViajesAceptadosPage> createState() => _MisViajesAceptadosPageState();
// }

// class _MisViajesAceptadosPageState extends State<MisViajesAceptadosPage> {
//   final _viajesService = ViajesService();

//   @override
//   Widget build(BuildContext context) {
//     return PageLayout(
//       icon: Icons.alternate_email,
//       title: 'Mis Cargas Aceptadas',

//       child: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _viajesService.obtenerMisViajesAceptados(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final viajes = snapshot.data ?? [];

//           if (viajes.isEmpty) {
//             return const Center(
//               child: Text("No tienes viajes aceptados pendientes."),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: viajes.length,
//             itemBuilder: (context, index) {
//               final viaje = viajes[index];
//               final creador = viaje['creador'];

//               return Card(
//                 elevation: 4,
//                 margin: const EdgeInsets.only(bottom: 20),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Column(
//                   children: [
//                     ListTile(
//                       leading: const CircleAvatar(
//                         backgroundColor: Colors.green,
//                         child: Icon(Icons.local_shipping, color: Colors.white),
//                       ),
//                       title: Text(
//                         "${viaje['origen']['nombre']} ➔ ${viaje['destino']['nombre']}",
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         "Fecha Programada: ${viaje['fecha_viaje']}",
//                       ),
//                     ),
//                     const Divider(),
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           _rowInfo(
//                             Icons.person,
//                             "Cliente: ${creador['nombre']}",
//                           ),
//                           const SizedBox(height: 8),
//                           _rowInfo(
//                             Icons.description,
//                             "Carga: ${viaje['descripcion_carga']}",
//                           ),
//                           const SizedBox(height: 8),
//                           _rowInfo(
//                             Icons.scale,
//                             "Peso: ${viaje['peso_estimado']} Ton.",
//                           ),
//                           const SizedBox(height: 15),

//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               // BOTÓN LLAMAR
//                               OutlinedButton.icon(
//                                 onPressed:
//                                     () => launchUrl(
//                                       Uri.parse("tel:${creador['telefono']}"),
//                                     ),
//                                 icon: const Icon(Icons.phone),
//                                 label: const Text("Llamar"),
//                               ),
//                               // BOTÓN VER EN MAPA O INICIAR
//                               ElevatedButton.icon(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.indigo,
//                                 ),
//                                 onPressed:
//                                     () => context.push(
//                                       '/detalle-viaje/${viaje['id']}',
//                                     ), //=> _abrirMapa(viaje),
//                                 icon: const Icon(
//                                   Icons.map,
//                                   color: Colors.white,
//                                 ),
//                                 label: const Text(
//                                   "Ver Ruta",
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                               ElevatedButton.icon(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.green.shade700,
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 onPressed:
//                                     () => _confirmarEntrega(
//                                       context,
//                                       viaje['id'].toString(),
//                                       viaje['creador_id'].toString(),
//                                       viaje['origen']['nombre'],
//                                       viaje['destino']['nombre'],
//                                     ),
//                                 icon: const Icon(Icons.check_circle_outline),
//                                 label: const Text("Entregado"),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _abrirMapa(Map<String, dynamic> viaje) async {
//     final double latOr = viaje['origen']['latitud'];
//     final double lonOr = viaje['origen']['longitud'];
//     final double latDes = viaje['destino']['latitud'];
//     final double lonDes = viaje['destino']['longitud'];

//     // Formato: https://google.com
//     final Uri url = Uri.parse('https://www.google.com/maps');

//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     } else {
//       AppService.showAlert("No se pudo abrir el mapa");
//       // AppService.showAlert(
//       //   context,
//       //   "No se pudo abrir el mapa",
//       //   backgroundColor: Colors.red,
//       // );
//     }
//   }

//   void _confirmarEntrega(
//     BuildContext context,
//     String id,
//     String creadorId,
//     String origenNombre,
//     String destinoNombre,
//   ) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text("¿Confirmar entrega?"),
//             content: const Text(
//               "El viaje se marcará como completado y se moverá a tu historial.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("CANCELAR"),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                 onPressed: () async {
//                   try {
//                     await _viajesService.finalizarViaje(
//                       id,
//                       creadorId,
//                       origenNombre,
//                       destinoNombre,
//                     );
//                     if (context.mounted) {
//                       Navigator.pop(context);
//                       setState(() {}); // Refrescamos la lista actual
//                       AppService.showAlert("✅ Viaje finalizado con éxito");
//                       // AppService.showAlert(
//                       //   context,
//                       //   "✅ Viaje finalizado con éxito",
//                       //   backgroundColor: Colors.green,
//                       // );
//                     }
//                   } catch (e) {
//                     print(e);
//                   }
//                 },
//                 child: const Text(
//                   "CONFIRMAR",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   Widget _rowInfo(IconData icon, String texto) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.grey),
//         const SizedBox(width: 10),
//         Text(texto),
//       ],
//     );
//   }
// }
