// import 'package:cargasuy/services/app_state.dart';
// import 'package:cargasuy/widgets/add_client_dialog.dart';
// import 'package:flutter/material.dart';
// import '../models/cliente.dart';
// import 'package:intl/intl.dart';

// class ClientesVIPPage extends StatefulWidget {
//   const ClientesVIPPage({super.key});

//   @override
//   State<ClientesVIPPage> createState() => _ClientesVIPPageState();
// }

// class _ClientesVIPPageState extends State<ClientesVIPPage> {
//   Cliente? _clienteSeleccionado; // Guarda el cliente para mostrar sus detalles
//   bool _showPanel = false; // Controla si el panel está abierto o cerrado
//   late List<Cliente> _filtrados;
//   int _rowsPerPage = 10; // Cuántas filas ver por página
//   int _currentPage = 0; // Página actual (empieza en 0)

//   bool _isTableLoading = false;

//   // Datos de ejemplo
//   final List<Cliente> _clientes = List.generate(
//     20,
//     (i) => Cliente(
//       nombre: "Cliente $i",
//       email: "correo$i@test.com",
//       status: i % 2 == 0 ? "Activo" : "Pendiente",
//       ultimaEdicion: DateTime.now(),
//     ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // 1. El Row principal DEBE estar en un Scaffold sin ScrollView externo
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // LADO IZQUIERDO: CONTENIDO PRINCIPAL
//           Expanded(
//             flex: 3,
//             child: Column(
//               children: [
//                 _buildTopBar(), // Buscador y Título
//                 // 2. La tabla DEBE estar en un Expanded para recibir altura limitada
//                 Expanded(child: _buildTableSection()),

//                 _buildPaginationBar(), // Tu barra de páginas
//               ],
//             ),
//           ),

//           // LADO DERECHO: PANEL LATERAL (Si lo tienes implementado)
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             width: _showPanel ? 400 : 0,
//             decoration: BoxDecoration(
//               color: Theme.of(context).cardColor,
//               border: Border(
//                 left: BorderSide(color: Theme.of(context).dividerColor),
//               ),
//               boxShadow:
//                   _showPanel
//                       ? [const BoxShadow(color: Colors.black12, blurRadius: 10)]
//                       : [],
//             ),
//             child: _showPanel ? _buildSidePanel() : const SizedBox.shrink(),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _filtrados = _clientes;
//   }

//   // Función para simular o ejecutar la carga de datos
//   Future<void> _refreshTableData() async {
//     setState(() => _isTableLoading = true);
//     // Simulamos una pequeña latencia de red/procesamiento
//     await Future.delayed(const Duration(milliseconds: 500));
//     setState(() => _isTableLoading = false);
//   }

//   final TextEditingController _pageJumpController = TextEditingController();

//   void _filtrar(String query) {
//     _refreshTableData();
//     setState(() {
//       _currentPage = 0;
//       _filtrados =
//           _clientes
//               .where(
//                 (c) => c.nombre.toLowerCase().contains(query.toLowerCase()),
//               )
//               .toList();
//     });
//   }

//   // Función para obtener solo los datos de la página actual
//   List<Cliente> get _datosPaginados {
//     int start = _currentPage * _rowsPerPage;
//     int end = start + _rowsPerPage;
//     if (end > _filtrados.length) end = _filtrados.length;
//     if (start > end) return []; // Caso de seguridad por filtros
//     return _filtrados.sublist(start, end);
//   }

//   Widget _buildTopBar() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         bool isNarrow = constraints.maxWidth < 600;

//         return Padding(
//           padding: EdgeInsets.all(24.0),
//           child: Row(
//             children: [
//               _buildFloatingSearchBar(), // El que ya creamos
//               const SizedBox(width: 16),
//               if (!isNarrow)
//                 ElevatedButton.icon(
//                   onPressed:
//                       () {}, //=> ExcelService.exportClientes(_filtrados),
//                   icon: const Icon(Icons.table_view_rounded, size: 18),
//                   label: const Text("Excel"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green.shade700,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 18,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                 ),
//               if (!isNarrow) const SizedBox(width: 5),
//               if (!isNarrow)
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     final result = await showDialog<Map<String, String>>(
//                       context: context,
//                       builder: (context) => const AddClientDialog(),
//                     );
//                   },
//                   icon: const Icon(Icons.add),
//                   label: Text("Agregar"),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 16,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildFloatingSearchBar() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Container(
//       width: 400, // Ancho fijo para que no se estire en toda la web
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(30), // Estilo "píldora"
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
//             blurRadius: 15,
//             offset: const Offset(0, 5), // Sombra hacia abajo
//           ),
//         ],
//       ),
//       child: TextField(
//         onChanged: (value) {
//           setState(() {
//             _currentPage = 0; // REGLA DE ORO: Resetear página al buscar
//             _filtrar(value); // Tu función de filtrado
//           });
//         },
//         decoration: InputDecoration(
//           hintText: "Buscar por nombre o email...",
//           hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
//           prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
//           // Quitamos los bordes por defecto para que luzca limpio
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 15,
//           ),
//           // Botón para limpiar la búsqueda rápido
//           suffixIcon: IconButton(
//             icon: const Icon(Icons.close, size: 18),
//             onPressed: () {
//               // Aquí limpiarías el controlador si usas uno
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTableSection() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Calculamos anchos proporcionales para que sea responsivo
//         double totalWidth =
//             constraints.maxWidth > 800 ? constraints.maxWidth : 800;
//         double colNombre = totalWidth * 0.3;
//         double colDireccio = totalWidth * 0.35;
//         double colEstado = totalWidth * 0.13;
//         double colAciones = totalWidth * 0.15;

//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 24),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.black),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: SizedBox(
//                 width: totalWidth,
//                 child: Column(
//                   children: [
//                     // --- ENCABEZADO FIJO ---
//                     _buildHeader(colNombre, colDireccio, colEstado, colAciones),

//                     // --- CUERPO SCROLLABLE ---
//                     // 3. Usamos Expanded aquí para que el scroll vertical
//                     // sepa cuánto espacio tiene disponible.
//                     SizedBox(
//                       height: 3, // Altura mínima para que no desplace la tabla
//                       child:
//                           _isTableLoading
//                               ? const LinearProgressIndicator(
//                                 backgroundColor: Colors.transparent,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Colors.indigo,
//                                 ),
//                               )
//                               : const Divider(
//                                 height: 1,
//                                 thickness: 0.5,
//                               ), // Línea sutil si no carga
//                     ),

//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: _datosPaginados.length,
//                         itemBuilder: (context, index) {
//                           return _buildRow(
//                             _datosPaginados[index],
//                             colNombre,
//                             colDireccio,
//                             colEstado,
//                             colAciones,
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader(double w1, double w2, double w3, double w4) {
//     return Container(
//       color: Colors.grey.withOpacity(0.1),
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: Row(
//         children: [
//           _cell("Nombre", w1, isHeader: true),
//           _cell("Email", w2, isHeader: true),
//           _cell("Estado", w3, isHeader: true),
//           _cell("Acciones", w4, isHeader: true),
//         ],
//       ),
//     );
//   }

//   Widget _buildRow(
//     Cliente cliente,
//     double w1,
//     double w2,
//     double w3,
//     double w4,
//   ) {
//     return Container(
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: Colors.black)),
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         children: [
//           _cell(cliente.nombre, w1),
//           _cell(cliente.email, w2),
//           _buildStatusCell(cliente.status, w3),
//           _buildActionCell(cliente, w4),
//         ],
//       ),
//     );
//   }

//   _buildActionCell(Cliente cliente, double width) {
//     return SizedBox(
//       width: width,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.visibility_outlined),
//               onPressed: () => _verDetalles(cliente), // <--- Abre el panel
//             ),
//             IconButton(
//               icon: const Icon(Icons.edit),
//               onPressed: () => _verDetalles(cliente), // <--- Abre el panel
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _verDetalles(Cliente cliente) {
//     setState(() {
//       _clienteSeleccionado = cliente;
//       _showPanel = true;
//     });
//   }

//   void _cerrarPanel() {
//     setState(() {
//       _showPanel = false;
//     });
//   }

//   Widget _cell(String text, double width, {bool isHeader = false}) {
//     return SizedBox(
//       width: width,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Text(
//           text,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(
//             fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCell(String status, double width) {
//     return SizedBox(
//       width: width,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Align(
//           alignment: Alignment.centerLeft,
//           child: _buildStatusBadge(status), // Tu función de Badge anterior
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusBadge(String status) {
//     // Definimos los colores según el texto del estado
//     final bool isActive = status.toLowerCase() == 'activo';
//     final Color color = isActive ? Colors.green : Colors.orange;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1), // Fondo suave con transparencia
//         borderRadius: BorderRadius.circular(
//           20,
//         ), // Bordes muy redondeados tipo "píldora"
//         border: Border.all(
//           color: color.withOpacity(0.4),
//           width: 1,
//         ), // Borde sutil
//       ),
//       child: Text(
//         status.toUpperCase(), // Texto en mayúsculas para estilo "Badge"
//         style: TextStyle(
//           color: color,
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 0.5,
//         ),
//       ),
//     );
//   }

//   int get _totalPages =>
//       (_filtrados.length / _rowsPerPage).ceil() == 0
//           ? 1
//           : (_filtrados.length / _rowsPerPage).ceil();

//   // Función para ir a una página específica
//   void _goToPage(int page) {
//     _refreshTableData();
//     setState(() {
//       _currentPage = page;
//     });
//   }

//   Widget _buildPageJump() {
//     return Row(
//       children: [
//         const Text(
//           "Saltar a:",
//           style: TextStyle(fontSize: 13, color: Colors.grey),
//         ),
//         const SizedBox(width: 8),
//         SizedBox(
//           width: 60,
//           height: 35,
//           child: TextField(
//             controller: _pageJumpController,
//             keyboardType: TextInputType.number,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 13),
//             decoration: InputDecoration(
//               contentPadding: const EdgeInsets.symmetric(vertical: 0),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               hintText: "N°",
//             ),
//             onSubmitted: _jumpToPage, // Salta al presionar Enter
//           ),
//         ),
//       ],
//     );
//   }

//   void _jumpToPage(String value) {
//     int? targetPage = int.tryParse(value);
//     // Validamos que sea un número, que no sea menor a 1 ni mayor al total
//     if (targetPage != null && targetPage > 0 && targetPage <= _totalPages) {
//       _goToPage(targetPage - 1); // Restamos 1 porque el índice empieza en 0
//       _pageJumpController.clear(); // Limpiamos después de saltar
//       FocusScope.of(context).unfocus(); // Quitamos el teclado/foco
//     } else {
//       AppService.showAlert("Página no válida");
//       _pageJumpController.clear();
//     }
//   }

//   Widget _buildRowsPerPageSelector() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Text(
//           "Filas por página:",
//           style: TextStyle(fontSize: 13, color: Colors.grey),
//         ),
//         const SizedBox(width: 8),
//         DropdownButton<int>(
//           value: _rowsPerPage,
//           icon: const Icon(Icons.arrow_drop_down, size: 18),
//           elevation: 16,
//           style: TextStyle(
//             color: Theme.of(context).colorScheme.primary,
//             fontSize: 13,
//             fontWeight: FontWeight.bold,
//           ),
//           underline: Container(
//             height: 1,
//             color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
//           ),
//           onChanged: (int? newValue) {
//             if (newValue != null) {
//               setState(() {
//                 _rowsPerPage = newValue;
//                 _currentPage =
//                     0; // REGLA DE ORO: Siempre volver a la página 1 al cambiar el tamaño
//               });
//               _refreshTableData(); // Llama a la animación de carga sutil que creamos
//             }
//           },
//           items:
//               <int>[10, 20, 50].map<DropdownMenuItem<int>>((int value) {
//                 return DropdownMenuItem<int>(
//                   value: value,
//                   child: Text(value.toString()),
//                 );
//               }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildPaginationBar() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Si el ancho es menor a 600px (típico cuando el panel está abierto),
//         // cambiamos el diseño para que no desborde.
//         bool isNarrow = constraints.maxWidth < 600;

//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             border: Border(
//               top: BorderSide(
//                 color: Theme.of(context).dividerColor,
//                 width: 0.5,
//               ),
//             ),
//           ),
//           child: Wrap(
//             // Wrap evita el error de "overflow" al pasar a la siguiente línea
//             alignment: WrapAlignment.spaceBetween,
//             crossAxisAlignment: WrapCrossAlignment.center,
//             runSpacing: 10, // Espacio vertical si los elementos saltan de línea
//             children: [
//               // IZQUIERDA: Selector y Salto
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildRowsPerPageSelector(),
//                   const SizedBox(width: 20),
//                   _buildPageJump(),
//                 ],
//               ),

//               // DERECHA: Controles de página
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (!isNarrow) ...[
//                     // Ocultamos botones extras si hay muy poco espacio
//                     IconButton(
//                       icon: const Icon(Icons.first_page, size: 20),
//                       onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
//                     ),
//                   ],
//                   IconButton(
//                     icon: const Icon(Icons.chevron_left),
//                     onPressed:
//                         _currentPage > 0
//                             ? () => _goToPage(_currentPage - 1)
//                             : null,
//                   ),

//                   // Texto de estado en lugar de botones numéricos si es muy estrecho
//                   Text(
//                     isNarrow
//                         ? "${_currentPage + 1} / $_totalPages"
//                         : "Página ${_currentPage + 1} de $_totalPages",
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   IconButton(
//                     icon: const Icon(Icons.chevron_right),
//                     onPressed:
//                         (_currentPage + 1) < _totalPages
//                             ? () => _goToPage(_currentPage + 1)
//                             : null,
//                   ),
//                   if (!isNarrow) ...[
//                     IconButton(
//                       icon: const Icon(Icons.last_page, size: 20),
//                       onPressed:
//                           (_currentPage + 1) < _totalPages
//                               ? () => _goToPage(_totalPages - 1)
//                               : null,
//                     ),
//                   ],
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSidePanel() {
//     if (_clienteSeleccionado == null) return const SizedBox.shrink();

//     return Column(
//       children: [
//         // Cabecera del panel
//         Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "Detalles",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: _cerrarPanel,
//               ),
//             ],
//           ),
//         ),
//         const Divider(),

//         // Contenido del detalle con Scroll propio
//         Expanded(
//           child: ListView(
//             padding: const EdgeInsets.all(20),
//             children: [
//               _infoTile(Icons.person, "Nombre", _clienteSeleccionado!.nombre),
//               _infoTile(Icons.email, "Email", _clienteSeleccionado!.email),
//               _infoTile(
//                 Icons.check_circle,
//                 "Estado",
//                 _clienteSeleccionado!.status,
//               ),
//               const SizedBox(height: 30),
//               ElevatedButton.icon(
//                 onPressed: () => AppService.showAlert("Editando..."),
//                 icon: const Icon(Icons.edit),
//                 label: const Text("Editar Cliente"),
//               ),
//               const SizedBox(height: 12),
//               OutlinedButton.icon(
//                 onPressed:
//                     () => _confirmarEliminacion(context, _clienteSeleccionado!),
//                 icon: const Icon(Icons.delete_outline, color: Colors.red),
//                 label: const Text(
//                   "Eliminar Cliente",
//                   style: TextStyle(color: Colors.red),
//                 ),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.red),
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                 ),
//               ),
//               // ... dentro del ListView de _buildSidePanel, después de los botones
//               const Divider(height: 40),
//               _buildHistorial(_clienteSeleccionado!),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   void _confirmarEliminacion(BuildContext context, Cliente cliente) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text("¿Eliminar cliente?"),
//             content: Text(
//               "Esta acción no se puede deshacer. Se eliminará a ${cliente.nombre} de forma permanente.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Cancelar"),
//               ),
//               FilledButton(
//                 style: FilledButton.styleFrom(backgroundColor: Colors.red),
//                 onPressed: () {
//                   _eliminarCliente(cliente);
//                   Navigator.pop(context); // Cierra el diálogo
//                 },
//                 child: const Text("Eliminar"),
//               ),
//             ],
//           ),
//     );
//   }

//   void _eliminarCliente(Cliente cliente) {
//     // Usamos el servicio de carga que creamos antes
//     AppService.runWithLoading(() async {
//       await Future.delayed(const Duration(milliseconds: 800)); // Simula red

//       setState(() {
//         _clientes.remove(cliente);
//         _showPanel = false; // Cerramos el panel al eliminar
//       });

//       AppService.showAlert("Cliente eliminado con éxito");
//     });
//   }

//   Widget _infoTile(IconData icon, String label, String value) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.indigo),
//       title: Text(
//         label,
//         style: const TextStyle(fontSize: 12, color: Colors.grey),
//       ),
//       subtitle: Text(
//         value,
//         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _infoRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.indigo, size: 20),
//           const SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(color: Colors.grey, fontSize: 12),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w600,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHistorial(Cliente cliente) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Actividad Reciente",
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey,
//           ),
//         ),
//         const SizedBox(height: 15),

//         // Ítem del historial (puedes duplicar esto si tienes una lista de cambios)
//         Row(
//           children: [
//             Container(
//               width: 12,
//               height: 12,
//               decoration: const BoxDecoration(
//                 color: Colors.indigo,
//                 shape: BoxShape.circle,
//               ),
//             ),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Última actualización de datos",
//                     style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//                   ),
//                   Text(
//                     "${cliente.ultimaEdicion.day}/${cliente.ultimaEdicion.month}/${cliente.ultimaEdicion.year} - ${cliente.ultimaEdicion.hour}:${cliente.ultimaEdicion.minute.toString().padLeft(2, '0')}",
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // Pide pagina con botones con el numero de pagina

// // Widget _buildPaginationBar1() {
// //   return Container(
// //     padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
// //     child: Row(
// //       mainAxisAlignment:
// //           MainAxisAlignment.spaceBetween, // Distribuimos el espacio
// //       children: [
// //         // IZQUIERDA: Selector de filas por página
// //         Row(
// //           children: [
// //             const Text(
// //               "Filas por página: ",
// //               style: TextStyle(fontSize: 13, color: Colors.grey),
// //             ),
// //             DropdownButton<int>(
// //               value: _rowsPerPage,
// //               underline: const SizedBox(),
// //               items:
// //                   [10, 20, 50].map((int value) {
// //                     return DropdownMenuItem<int>(
// //                       value: value,
// //                       child: Text("$value"),
// //                     );
// //                   }).toList(),
// //               onChanged:
// //                   (val) => setState(() {
// //                     _rowsPerPage = val!;
// //                     _currentPage = 0;
// //                   }),
// //             ),
// //             const SizedBox(width: 32),
// //             _buildPageJump(),
// //           ],
// //         ),

// //         // DERECHA: Navegación numérica y flechas
// //         Row(
// //           children: [
// //             // Botón IR AL PRINCIPIO
// //             IconButton(
// //               icon: const Icon(Icons.first_page),
// //               onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
// //               tooltip: "Primera página",
// //             ),

// //             // Botón ANTERIOR
// //             IconButton(
// //               icon: const Icon(Icons.chevron_left),
// //               onPressed:
// //                   _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
// //             ),

// //             // NÚMEROS DE PÁGINA (Generamos botones dinámicos)
// //             const SizedBox(width: 10),
// //             ...List.generate(_totalPages, (index) {
// //               // Si hay demasiadas páginas, podrías limitar cuáles mostrar,
// //               // pero por ahora mostraremos todas las básicas.
// //               bool isCurrent = _currentPage == index;
// //               return Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 4),
// //                 child: InkWell(
// //                   onTap: () => _goToPage(index),
// //                   borderRadius: BorderRadius.circular(8),
// //                   child: AnimatedContainer(
// //                     duration: const Duration(milliseconds: 200),
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 12,
// //                       vertical: 8,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: isCurrent ? Colors.indigo : Colors.transparent,
// //                       borderRadius: BorderRadius.circular(8),
// //                       border: Border.all(
// //                         color: isCurrent ? Colors.indigo : Colors.grey.shade300,
// //                       ),
// //                     ),
// //                     child: Text(
// //                       "${index + 1}",
// //                       style: TextStyle(
// //                         color: isCurrent ? Colors.white : Colors.grey.shade700,
// //                         fontWeight:
// //                             isCurrent ? FontWeight.bold : FontWeight.normal,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               );
// //             }),
// //             const SizedBox(width: 10),

// //             // Botón SIGUIENTE
// //             IconButton(
// //               icon: const Icon(Icons.chevron_right),
// //               onPressed:
// //                   (_currentPage + 1) < _totalPages
// //                       ? () => _goToPage(_currentPage + 1)
// //                       : null,
// //             ),

// //             // Botón IR AL FINAL
// //             IconButton(
// //               icon: const Icon(Icons.last_page),
// //               onPressed:
// //                   (_currentPage + 1) < _totalPages
// //                       ? () => _goToPage(_totalPages - 1)
// //                       : null,
// //               tooltip: "Última página",
// //             ),
// //           ],
// //         ),
// //       ],
// //     ),
// //   );
// // }
