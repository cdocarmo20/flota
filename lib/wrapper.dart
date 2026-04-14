import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/sidebar.dart';
import 'widgets/overlays.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final miId = Supabase.instance.client.auth.currentUser!.id;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).cardColor,
            elevation: 1, // Una sombra sutil para despegarlo del fondo
            title: Row(
              children: [
                // 1. EL LOGO
                Image.asset(
                  'assets/logo.png',
                  height: 35, // Tamaño compacto para el AppBar
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                // 2. NOMBRE DE LA APP
                const Text(
                  'CargasUY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FutureBuilder<String?>(
                    future: AppService.getNombreUsuario(), // Llamada al método
                    builder: (context, snapshot) {
                      // Mientras la consulta está en viaje
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      // Cuando ya tenemos el nombre o si hubo un error
                      final nombre = snapshot.data ?? "Usuario";

                      return Padding(
                        padding: const EdgeInsets.only(right: 1),
                        child: Center(
                          child: Text(
                            "Hola, $nombre, ¿Qué carga vamos a mover hoy? ",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('notificaciones')
                    .stream(primaryKey: ['id'])
                    .eq(
                      'usuario_id',
                      Supabase.instance.client.auth.currentUser!.id,
                    ),
                // Sacamos el .eq('leida', false) de aquí para evitar el error de tipo
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Icon(Icons.error_outline);

                  // FILTRAMOS AQUÍ CON DART:
                  final todas = snapshot.data ?? [];
                  final noLeidas =
                      todas.where((n) => n['leida'] == false).toList();
                  int contador = noLeidas.length;

                  return IconButton(
                    icon: Badge(
                      isLabelVisible: contador > 0,
                      label: Text('$contador'),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.grey,
                      ),
                    ),
                    onPressed:
                        () => _mostrarPanelNotificaciones(context, noLeidas),
                  );
                },
              ),
              const SizedBox(width: 20),
            ],
          ),
          body: Row(
            children: [
              const CustomSidebar(),
              const VerticalDivider(width: 1, thickness: 0.5),
              Expanded(child: child),
            ],
          ),
        ),
        const LoadingOverlay(),
        const NotificationOverlay(),
      ],
    );
  }

  void _mostrarPanelNotificaciones(
    BuildContext context,
    List<Map<String, dynamic>> notificaciones,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Notificaciones Recientes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              if (notificaciones.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No tienes avisos nuevos"),
                ),
              ...notificaciones.map(
                (n) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.deepOrangeAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    n['mensaje'], // Ej: "🏁 Carga Entregada: Montevideo ➔ Rivera"
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "Recibido: ${(n['created_at'])}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () async {
                    // Lógica para marcar como leída...
                    await Supabase.instance.client
                        .from('notificaciones')
                        .update({'leida': true})
                        .eq('id', n['id']);
                    // print(n['viaje_id']);
                    Navigator.pop(context);
                    context.push('/detalle-viaje/${n['viaje_id']}');

                    // OPCIONAL: Podrías navegar a la página de "Mis Cargas" directamente
                    // context.go('/mis-cargas');
                  },
                ),
              ),
            ],
          ),
    );
  }
}
