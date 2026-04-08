// // lib/pages/viajes_disponibles_page.dart

// import 'package:demos/models/viaje.dart';
// import 'package:flutter/material.dart';

// Widget _buildCardViaje(Viaje viaje) {
//   return Card(
//     margin: const EdgeInsets.only(bottom: 16),
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _rutaInfo(viaje.origen, viaje.destino),
//               _badgeEstado(viaje.estado),
//             ],
//           ),
//           const Divider(height: 30),
//           Row(
//             children: [
//               const Icon(Icons.inventory_2_outlined, size: 18),
//               const SizedBox(width: 8),
//               Text(viaje.descripcion),
//               const Spacer(),
//               Text(
//                 "${viaje.peso} Ton",
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           if (viaje.estado == 'PENDIENTE')
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => _confirmarAceptacion(viaje),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text("ACEPTAR CARGA"),
//               ),
//             ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _rutaInfo(String origen, String destino) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         origen,
//         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//       ),
//       const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
//       Text(
//         destino,
//         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//       ),
//     ],
//   );
// }
