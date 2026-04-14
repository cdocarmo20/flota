import 'package:cargasuy/services/app_state.dart';
import 'package:cargasuy/services/db/viajes_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child; // Aquí irá el contenido de cada página
  final List<Widget>? actions; // Botones opcionales a la derecha

  const PageLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent, // El fondo lo da el Wrapper
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ENCABEZADO DINÁMICO
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Gestión y administración de $title",
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 32),

            // 2. CUERPO DE LA PÁGINA (TARJETA DE CONTENIDO)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:cargasuy/services/app_state.dart';
// import 'package:cargasuy/services/db/viajes_service.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class PageLayout extends StatefulWidget {
//   final String title;
//   final IconData icon;
//   final Widget child; // Aquí irá el contenido de cada página
//   final List<Widget>? actions; // Botones opcionales a la derecha

//   const PageLayout({
//     super.key,
//     required this.title,
//     required this.icon,
//     required this.child,
//     this.actions,
//   });

//   @override
//   State<PageLayout> createState() => _PageLayoutState();
// }

// class _PageLayoutState extends State<PageLayout> {
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     // En el initState de tu Dashboard o PageLayout
//     Supabase.instance.client
//         .from('notificaciones')
//         .stream(primaryKey: ['id'])
//         .eq('usuario_id', Supabase.instance.client.auth.currentUser!.id)
//         .listen((List<Map<String, dynamic>> data) {
//           // Si llega una notificación nueva que no esté leída
//           final nuevas = data.where((n) => n['leida'] == false).toList();
//           if (nuevas.isNotEmpty) {
//             // Mostramos la alerta "chiva" que creamos en AppService
//             AppService.showAlert(nuevas.last['mensaje']);
//             // AppService.showAlert(
//             //   context,
//             //   nuevas.last['mensaje'],
//             //   backgroundColor: Colors.green,
//             // );
//             // Marcar como leída para que no vuelva a saltar
//             ViajesService().marcarNotificacionLeida(nuevas.last['id']);
//           }
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return Scaffold(
//       backgroundColor: Colors.transparent, // El fondo lo da el Wrapper
//       body: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 1. ENCABEZADO DINÁMICO
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: colorScheme.primaryContainer,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     widget.icon,
//                     color: colorScheme.primary,
//                     size: 28,
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.title,
//                       style: const TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "Gestión y administración de ${widget.title}",
//                       style: TextStyle(
//                         color: colorScheme.outline,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//               ],
//             ),

//             const SizedBox(height: 32),

//             // 2. CUERPO DE LA PÁGINA (TARJETA DE CONTENIDO)
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).cardColor,
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(
//                     color: colorScheme.outlineVariant.withOpacity(0.5),
//                   ),
//                 ),
//                 child: widget.child,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
