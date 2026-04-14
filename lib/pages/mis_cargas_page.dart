import 'package:cargasuy/pages/edita_viaje_page.dart';
import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/db/viajes_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Para llamar al cliente

class MisCargasPage extends StatefulWidget {
  const MisCargasPage({super.key});

  @override
  State<MisCargasPage> createState() => _MisCargasPageState();
}

class _MisCargasPageState extends State<MisCargasPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _futureViajes;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // Aquí guardamos lo que el usuario escribe

  @override
  void initState() {
    super.initState();
    // _cargarViajes(); // Carga inicial
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PageLayout(
        icon: Icons.alternate_email,
        title: 'Mis Cargas Publicadas',

        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Activas", icon: Icon(Icons.check_circle)),
                Tab(text: "Historial", icon: Icon(Icons.hourglass_top)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(esHistorial: false),
                  _buildTabContent(esHistorial: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    setState(() {});
  }

  Widget _buildTabContent({required bool esHistorial}) {
    return Column(
      children: [
        _buildSearchBar(), // Colocamos el buscador arriba de la lista
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future:
                esHistorial
                    ? ViajesService().obtenerHistorialCargas()
                    : ViajesService().obtenerMisCargasActivas(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              // FILTRADO EN TIEMPO REAL
              final cargasFiltradas =
                  snapshot.data!.where((carga) {
                    final destino =
                        carga['destino']['nombre'].toString().toLowerCase();
                    final descripcion =
                        (carga['descripcion_carga'] ?? "")
                            .toString()
                            .toLowerCase();
                    final origen =
                        carga['origen']['nombre'].toString().toLowerCase();

                    // El viaje aparece si el texto está en el destino O en la descripción
                    return destino.contains(_searchQuery) ||
                        descripcion.contains(_searchQuery) ||
                        origen.contains(_searchQuery);
                  }).toList();

              if (cargasFiltradas.isEmpty) {
                return const Center(
                  child: Text(
                    "No se encontraron resultados",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cargasFiltradas.length,
                itemBuilder: (context, index) {
                  return _buildCargaCard(cargasFiltradas[index], esHistorial);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCargaCard(Map<String, dynamic> carga, bool esHistorial) {
    final String estado =
        (carga['estado'] ?? 'PENDIENTE').toString().toUpperCase();

    final transportista = carga['transportista'];
    final vehiculo = carga['vehiculo'];
    Color colorEstado =
        carga['estado'] == 'CONFIRMADO' ? Colors.green : Colors.grey;
    return Card(
      elevation: esHistorial ? 1 : 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // Agregamos un borde sutil del color del estado si es historial
        side:
            esHistorial
                ? BorderSide(color: colorEstado.withOpacity(0.5), width: 1)
                : BorderSide.none,
      ),
      child: ExpansionTile(
        // El icono cambia de color según el estado en el historial
        leading: Icon(
          Icons.inventory_2,
          color: esHistorial ? colorEstado : Colors.deepOrangeAccent,
        ),
        title: Text(
          "${carga['origen']['nombre']} ➔ ${carga['destino']['nombre']}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // Texto gris oscuro para cancelados, verde para confirmados
            color: esHistorial ? colorEstado.withOpacity(0.8) : Colors.white,
          ),
        ),
        subtitle: Text(
          "Fecha Viaje: ${carga['fecha_viaje'] ?? 'A convenir'}",
          style: TextStyle(color: esHistorial ? Colors.grey : null),
        ),
        // Pasamos el color al badge para que haga juego
        trailing: _buildBadge(estado, esHistorial),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📝 Descripción: ${carga['descripcion_carga'] ?? 'Sin descripción'}",
                ),
                Text("⚖️ Peso: ${carga['peso_estimado']} Ton."),
                Text("💰 Oferta: \$${carga['precio_ofertado']}"),
                const Divider(),

                if (!esHistorial && estado == 'PENDIENTE')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text("Editar"),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditarViajePage(viaje: carga),
                            ),
                          );
                          _refresh();
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text("Cancelar"),
                        onPressed:
                            () => _confirmarCancelacion(carga['id'].toString()),
                      ),
                    ],
                  ),

                if (estado == 'ACEPTADO' ||
                    estado == 'FINALIZADO' ||
                    estado == 'CONFIRMADO') ...[
                  Text(
                    "🚛 DATOS DEL TRANSPORTE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // Si es historial, el título de transporte también se adapta
                      color: esHistorial ? colorEstado : Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (transportista != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person),
                      title: Text("Chofer: ${transportista['nombre']}"),
                      subtitle: Text("Teléfono: ${transportista['telefono']}"),
                      trailing:
                          esHistorial
                              ? null // No mostramos botón de llamada en el historial
                              : IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                ),
                                onPressed:
                                    () => launchUrl(
                                      Uri.parse(
                                        "tel:${transportista['telefono']}",
                                      ),
                                    ),
                              ),
                    ),
                  if (vehiculo != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_shipping),
                      title: Text("Vehículo: ${vehiculo['modelo']}"),
                      subtitle: Text("Patente: ${vehiculo['patente']}"),
                    ),
                ] else if (estado == 'PENDIENTE') ...[
                  const Text(
                    "⏳ Esperando que un transportista acepte tu carga...",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (estado != 'PENDIENTE') ...[
                  const Divider(),

                  // BOTÓN PARA IR AL DETALLE
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        // 1. Navegamos y esperamos a que el usuario regrese
                        await context.push('/detalle-viaje/${carga['id']}');

                        // 2. Al regresar de la pantalla de detalle, refrescamos la lista
                        _refresh(); // O la función que uses para cargar tus viajes
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text("VER DETALLES COMPLETOS"),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            esHistorial ? colorEstado : Colors.deepOrangeAccent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    // return Card(
    //   // Si es historial, lo hacemos más transparente/tenue
    //   // opacity: esHistorial ? 0.7 : 1.0,
    //   elevation: esHistorial ? 1 : 4,
    //   margin: const EdgeInsets.only(bottom: 15),
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    //   child: ExpansionTile(
    //     leading: Icon(
    //       Icons.inventory_2,
    //       color: esHistorial ? Colors.grey : Colors.deepOrangeAccent,
    //     ),
    //     title: Text(
    //       "${carga['origen']['nombre']} ➔ ${carga['destino']['nombre']}",
    //       style: TextStyle(
    //         fontWeight: FontWeight.bold,
    //         color: esHistorial ? Colors.grey.shade700 : Colors.white,
    //       ),
    //     ),
    //     subtitle: Text("Fecha Viaje: ${carga['fecha_viaje'] ?? 'A convenir'}"),
    //     trailing: _buildBadge(estado, esHistorial),
    //     children: [
    //       Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Text(
    //               "📝 Descripción: ${carga['descripcion_carga'] ?? 'Sin descripción'}",
    //             ),
    //             Text("⚖️ Peso: ${carga['peso_estimado']} Ton."),
    //             Text("💰 Oferta: \$${carga['precio_ofertado']}"),
    //             const Divider(),

    //             // Solo mostramos botones si la carga es PENDIENTE y no es Historial
    //             if (!esHistorial && estado == 'PENDIENTE')
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.end,
    //                 children: [
    //                   TextButton.icon(
    //                     icon: const Icon(Icons.edit, color: Colors.blue),
    //                     label: const Text("Editar"),
    //                     onPressed: () async {
    //                       await Navigator.push(
    //                         context,
    //                         MaterialPageRoute(
    //                           builder:
    //                               (context) => EditarViajePage(viaje: carga),
    //                         ),
    //                       );
    //                       _refresh();
    //                     },
    //                   ),
    //                   TextButton.icon(
    //                     icon: const Icon(Icons.cancel, color: Colors.red),
    //                     label: const Text("Cancelar"),
    //                     onPressed:
    //                         () => _confirmarCancelacion(carga['id'].toString()),
    //                   ),
    //                 ],
    //               ),

    //             if (estado == 'ACEPTADO' ||
    //                 estado == 'FINALIZADO' && transportista != null) ...[
    //               const Text(
    //                 "🚛 DATOS DEL TRANSPORTE",
    //                 style: TextStyle(
    //                   fontWeight: FontWeight.bold,
    //                   color: Colors.indigo,
    //                 ),
    //               ),
    //               const SizedBox(height: 10),
    //               ListTile(
    //                 contentPadding: EdgeInsets.zero,
    //                 leading: const Icon(Icons.person),
    //                 title: Text("Chofer: ${transportista['nombre']}"),
    //                 subtitle: Text("Teléfono: ${transportista['telefono']}"),
    //                 trailing: IconButton(
    //                   icon: const Icon(Icons.phone, color: Colors.green),
    //                   onPressed:
    //                       () => launchUrl(
    //                         Uri.parse("tel:${transportista['telefono']}"),
    //                       ),
    //                 ),
    //               ),
    //               if (vehiculo != null)
    //                 ListTile(
    //                   contentPadding: EdgeInsets.zero,
    //                   leading: const Icon(Icons.local_shipping),
    //                   title: Text("Vehículo: ${vehiculo['modelo']}"),
    //                   subtitle: Text("Patente: ${vehiculo['patente']}"),
    //                 ),
    //             ] else ...[
    //               const Text(
    //                 "⏳ Esperando que un transportista acepte tu carga...",
    //                 style: TextStyle(
    //                   fontStyle: FontStyle.italic,
    //                   color: Colors.grey,
    //                 ),
    //               ),
    //             ],
    //             const Divider(),
    //           ],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery =
                val.toLowerCase(); // Actualizamos el filtro al escribir
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar por origen, destino, descripcion...",
          prefixIcon: const Icon(Icons.search, color: Colors.deepOrangeAccent),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                  : null,
          filled: true,
          // fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Forma de cápsula
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildBadge(String estado, bool esHistorial) {
    Color color = Colors.orange;
    if (esHistorial)
      color = Colors.grey;
    else if (estado == 'ACEPTADO')
      color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmarCancelacion(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("¿Cancelar esta carga?"),
            content: const Text("Ya no será visible para los transportistas."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("VOLVER"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await ViajesService().cancelarViaje(id);
                    if (mounted) {
                      Navigator.pop(context);
                      _refresh();
                      // AppService.showAlert(context, "Carga cancelada", backgroundColor: Colors.orange);
                      AppService.showAlert("Carga cancelada");
                    }
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text(
                  "SÍ, CANCELAR",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
