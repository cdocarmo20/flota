import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _bannerInfo = {'localidad': '...', 'cantidad': 0};

  final _viajesService = ViajesService();
  bool _isLoading = true;
  Map<String, int> _stats = {
    'pendientes': 0,
    'aceptados': 0,
    'finalizados': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final stats = await _viajesService.obtenerEstadisticasDashboard(userId);
      final banner = await _viajesService.obtenerBannerInfo(userId);
      setState(() {
        _stats = stats;
        _isLoading = false;
        _bannerInfo = banner;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error cargando dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CargasUY - Mi Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDashboard,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _cargarDashboard,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocalidadBanner(),

                      const SizedBox(height: 20),

                      const Text(
                        "Resumen de Actividad",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // GRILLA DE ESTADÍSTICAS
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3,
                        children: [
                          _buildStatCard(
                            "Pendientes",
                            _stats['pendientes'].toString(),
                            Icons.timer_outlined,
                            Colors.orange,
                            () => context.push('/mis-cargas'),
                          ),
                          _buildStatCard(
                            "En Curso",
                            _stats['aceptados'].toString(),
                            Icons.local_shipping_outlined,
                            Colors.blue,
                            () => context.push('/mis-viajes-aceptados'),
                          ),
                          _buildStatCard(
                            "Completados",
                            _stats['finalizados'].toString(),
                            Icons.check_circle_outline,
                            Colors.green,
                            () => context.push('/historial'),
                          ),
                          _buildStatCard(
                            "Total Histórico",
                            _stats['total'].toString(),
                            Icons.analytics_outlined,
                            Colors.deepOrangeAccent,
                            null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        "Acciones Rápidas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // LISTA DE ACCIONES
                      _buildActionTile(
                        Icons.add_box,
                        "Publicar Nueva Carga",
                        "Solicita un transportista ahora",
                        () => context.push('/solicitar-viaje'),
                      ),
                      _buildActionTile(
                        Icons.search,
                        "Buscar Cargas Disponibles",
                        "Encuentra fletes cerca de ti",
                        () => context.push('/cargas-disponibles'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildLocalidadBanner() {
    final tieneCargas = _bannerInfo['cantidad'] > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              tieneCargas
                  ? [Colors.deepOrangeAccent, Colors.orange]
                  : [Colors.blueGrey, Colors.grey],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "En ${_bannerInfo['localidad']}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  tieneCargas
                      ? "Hay ${_bannerInfo['cantidad']} cargas disponibles"
                      : "No hay cargas nuevas cerca de ti",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (tieneCargas)
            ElevatedButton(
              onPressed: () => context.push('/buscar-cargas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
              ),
              child: const Text("VER"),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrangeAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
