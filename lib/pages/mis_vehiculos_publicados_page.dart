import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:flutter/material.dart';

class MisVehiculosPublicadosPage extends StatefulWidget {
  const MisVehiculosPublicadosPage({super.key});

  @override
  State<MisVehiculosPublicadosPage> createState() =>
      _MisVehiculosPublicadosPageState();
}

class _MisVehiculosPublicadosPageState
    extends State<MisVehiculosPublicadosPage> {
  final _viajeService = ViajesService();
  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;
  bool _estaCargando = false;

  @override
  void initState() {
    super.initState();
    _cargarMisVehiculos();
  }

  void _cargarMisVehiculos() async {
    setState(() => _cargando = true);
    try {
      final res = await _viajeService.obtenerMisVehiculosPublicados();
      setState(() => _resultados = res);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    Widget contenido = Column(
      children: [
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
                      child: Text("No has publicado vehículos aún"),
                    )
                    : ListView.builder(
                      key: ValueKey(_resultados.length),
                      padding: const EdgeInsets.all(10),
                      itemCount: _resultados.length,
                      itemBuilder:
                          (context, index) =>
                              _buildViajeCard(_resultados[index]),
                    ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mis Vehículos Publicados")),
        body: contenido,
      );
    } else {
      return PageLayout(
        title: "Mis Vehículos Publicados",
        icon: Icons.local_shipping,
        child: contenido,
      );
    }
  }

  Widget _buildViajeCard(Map<String, dynamic> viaje) {
    final String tipoCamion =
        viaje['vehiculo'] != null && viaje['vehiculo']['tipo_vehiculo'] != null
            ? viaje['vehiculo']['tipo_vehiculo']['nombre'] ?? 'No especificado'
            : 'No especificado';
    final interesado = viaje['interesado'];
    final String nombreInteresado =
        interesado != null
            ? (interesado['nombre'] ?? 'Usuario')
            : 'Sin solicitudes';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _buildBadgeEstado(viaje['estado'] ?? 'ACTIVO'),
              ],
            ),
            if (viaje['estado'] != 'ACTIVO' && interesado != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    radius: 12,
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreInteresado,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Solicitante",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
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
                        viaje['origen']['nombre'] ?? '',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        viaje['destino']['nombre'] ?? '',
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
                if (viaje['estado'] == 'RESERVADO')
                  ElevatedButton(
                    onPressed:
                        _estaCargando
                            ? null
                            : () => _procesarInicioViaje(viaje['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Iniciar Viaje"),
                  ),
                if (viaje['estado'] == 'EN TRANSITO')
                  ElevatedButton(
                    onPressed:
                        _estaCargando
                            ? null
                            : () => _procesarFinViaje(viaje['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Finalizar Viaje"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _procesarInicioViaje(String viajeId) async {
    setState(() => _estaCargando = true);
    try {
      await _viajeService.iniciarViajeVehiculo(viajeId);
      AppService.showAlert("✅ ¡Viaje iniciado con éxito!");
      _cargarMisVehiculos();
    } catch (e) {
      print(e);
      AppService.showAlert("❌ Error: ${e.toString()}");
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  Future<void> _procesarFinViaje(String viajeId) async {
    setState(() => _estaCargando = true);
    try {
      await _viajeService.finalizarViajeVehiculo(viajeId);
      AppService.showAlert("✅ ¡Viaje finalizado con éxito!");
      _cargarMisVehiculos();
    } catch (e) {
      AppService.showAlert("❌ Error: ${e.toString()}");
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  Widget _buildBadgeEstado(String estado) {
    Color color;
    switch (estado) {
      case 'ACTIVO':
        color = Colors.green;
        break;
      case 'RESERVADO':
        color = Colors.blue;
        break;
      case 'EN TRANSITO':
        color = Colors.orange;
        break;
      case 'FINALIZADO':
        color = Colors.grey;
        break;
      case 'CANCELADO':
        color = Colors.red;
        break;
      default:
        color = Colors.black54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return '';
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) return '';
    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }
}
