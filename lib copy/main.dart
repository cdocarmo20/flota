// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final prefs = await SharedPreferences.getInstance();

//   // Cargar modo oscuro guardado
//   final isDark = prefs.getBool('isDarkMode') ?? false;
//   themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

//   runApp(const MyApp());
// }

// // --- ENRUTADOR ---
// // final _router = GoRouter(
// //   initialLocation: '/',
// //   routes: [
// //     ShellRoute(
// //       builder: (context, state, child) => ResponsiveMainScreen(child: child),
// //       routes: [
// //         GoRoute(
// //           path: '/',
// //           builder: (context, state) => const DashboardContent(),
// //         ),
// //         GoRoute(
// //           path: '/web',
// //           builder:
// //               (context, state) => const Center(child: Text('🌐 Diseño Web')),
// //         ),
// //         GoRoute(
// //           path: '/mobile',
// //           builder:
// //               (context, state) => const Center(child: Text('📱 Apps Móviles')),
// //         ),
// //         GoRoute(
// //           path: '/config',
// //           builder: (context, state) => const Center(child: Text('⚙️ Ajustes')),
// //         ),
// //       ],
// //     ),
// //   ],
// // );

// final _router = GoRouter(
//   initialLocation: '/',
//   routes: [
//     ShellRoute(
//       builder: (context, state, child) => ResponsiveMainScreen(child: child),
//       routes: [
//         GoRoute(
//           path: '/',
//           pageBuilder:
//               (context, state) => CustomTransitionPage(
//                 key: state.pageKey,
//                 child: const DashboardContent(),
//                 transitionsBuilder: (
//                   context,
//                   animation,
//                   secondaryAnimation,
//                   child,
//                 ) {
//                   // Animación de Deslizamiento + Fade
//                   return FadeTransition(
//                     opacity: animation,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(
//                           0.1,
//                           0,
//                         ), // Empieza un poco a la derecha
//                         end: Offset.zero,
//                       ).animate(
//                         CurvedAnimation(
//                           parent: animation,
//                           curve: Curves.easeInOut,
//                         ),
//                       ),
//                       child: child,
//                     ),
//                   );
//                 },
//               ),
//         ),
//         GoRoute(
//           path: '/config',
//           pageBuilder:
//               (context, state) => CustomTransitionPage(
//                 key: state.pageKey,
//                 child: const Center(
//                   child: Text(
//                     '⚙️ Ajustes del Sistema',
//                     style: TextStyle(fontSize: 24),
//                   ),
//                 ),
//                 transitionsBuilder: (
//                   context,
//                   animation,
//                   secondaryAnimation,
//                   child,
//                 ) {
//                   return FadeTransition(
//                     opacity: animation,
//                     child: SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(0.1, 0),
//                         end: Offset.zero,
//                       ).animate(
//                         CurvedAnimation(
//                           parent: animation,
//                           curve: Curves.easeInOut,
//                         ),
//                       ),
//                       child: child,
//                     ),
//                   );
//                 },
//               ),
//         ),
//         // Agrega el mismo pageBuilder para /web y /mobile si lo deseas
//       ],
//     ),
//   ],
// );

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (_, mode, __) {
//         return MaterialApp.router(
//           routerConfig: _router,
//           themeMode: mode,
//           theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
//           darkTheme: ThemeData(
//             useMaterial3: true,
//             brightness: Brightness.dark,
//             colorSchemeSeed: Colors.indigo,
//           ),
//           debugShowCheckedModeBanner: false,
//         );
//       },
//     );
//   }
// }

// // --- LAYOUT PRINCIPAL ---
// class ResponsiveMainScreen extends StatefulWidget {
//   final Widget child;
//   const ResponsiveMainScreen({super.key, required this.child});
//   @override
//   State<ResponsiveMainScreen> createState() => _ResponsiveMainScreenState();
// }

// class _ResponsiveMainScreenState extends State<ResponsiveMainScreen> {
//   final ExpansionTileController _expansionController =
//       ExpansionTileController();
//   bool _isRailFixed = true;
//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadPreferences();
//   }

//   Future<void> _loadPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() => _isRailFixed = prefs.getBool('isRailFixed') ?? true);
//   }

//   Future<void> _toggleRail() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isRailFixed = !_isRailFixed;
//       prefs.setBool('isRailFixed', _isRailFixed);
//     });
//   }

//   void _handleKeyPress(KeyEvent event) {
//     final isControl =
//         HardwareKeyboard.instance.isControlPressed ||
//         HardwareKeyboard.instance.isMetaPressed;
//     if (isControl && event.logicalKey == LogicalKeyboardKey.keyK)
//       _showSearchModal(context);
//   }

//   int _calculateSelectedIndex(BuildContext context) {
//     final String location = GoRouterState.of(context).uri.toString();
//     if (location == '/') return 0;
//     if (location == '/config') return 1;
//     // Si estás en una subpágina de servicios, podrías devolver -1 o mantener el anterior
//     return 0;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = themeNotifier.value == ThemeMode.dark;
//     return KeyboardListener(
//       focusNode: FocusNode(),
//       onKeyEvent: _handleKeyPress,
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           bool isMobile = constraints.maxWidth < 900;
//           return Scaffold(
//             appBar: isMobile ? AppBar(title: const Text('Admin Panel')) : null,
//             drawer: isMobile ? _buildDrawer() : null,
//             backgroundColor:
//                 isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
//             body: Row(
//               children: [
//                 if (!isMobile) _buildSidebar(),
//                 if (!isMobile) const VerticalDivider(width: 1),
//                 Expanded(child: widget.child),
//               ],
//             ),
//             floatingActionButton: FloatingActionButton.extended(
//               onPressed: () {},
//               label: const Text('Soporte'),
//               icon: const Icon(Icons.support_agent),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSidebar() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: _isRailFixed ? 260 : 80,
//       color:
//           themeNotifier.value == ThemeMode.dark
//               ? const Color(0xFF1E1E26)
//               : Colors.white,
//       child: NavigationRail(
//         extended: _isRailFixed,
//         backgroundColor: Colors.transparent,
//         selectedIndex: _calculateSelectedIndex(context),
//         onDestinationSelected: (int index) {
//           setState(() {
//             _selectedIndex = index;
//           });

//           // VINCULAMOS CADA ÍNDICE CON SU RUTA
//           if (index == 0) context.go('/'); // Dashboard
//           if (index == 1) context.go('/config'); // Ajustes
//         },
//         leading: _buildSidebarHeader(),
//         trailing: _buildSidebarFooter(),
//         destinations: const [
//           NavigationRailDestination(
//             icon: Icon(Icons.dashboard_outlined),
//             selectedIcon: Icon(Icons.dashboard),
//             label: Text('Dashboard'),
//           ),
//           NavigationRailDestination(
//             icon: Icon(Icons.settings_outlined),
//             label: Text('Ajustes'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarHeader() {
//     return Column(
//       children: [
//         Align(
//           alignment: _isRailFixed ? Alignment.centerRight : Alignment.center,
//           child: IconButton(
//             icon: Icon(_isRailFixed ? Icons.menu_open : Icons.menu),
//             onPressed: _toggleRail,
//           ),
//         ),
//         const FlutterLogo(size: 40),
//         const SizedBox(height: 20),
//         if (_isRailFixed) ...[
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: TextField(
//               onSubmitted: (_) => _showSearchModal(context),
//               decoration: InputDecoration(
//                 hintText: 'Buscar...',
//                 prefixIcon: const Icon(Icons.search, size: 18),
//                 suffixIcon: const Icon(Icons.keyboard_command_key, size: 12),
//                 isDense: true,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//           Theme(
//             data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//             // child: ExpansionTile(
//             //   controller: _expansionController,
//             //   leading: const Icon(Icons.layers_outlined),
//             //   title: const Text('Servicios', style: TextStyle(fontSize: 14)),
//             //   children: [
//             //     _buildSubItem(Icons.language, 'Web Design', '/web'),
//             //     _buildSubItem(Icons.phone_android, 'Mobile App', '/mobile'),
//             //   ],
//             // ),
//             child: ExpansionTile(
//               controller: _expansionController,
//               leading: const Icon(Icons.layers_outlined),
//               title: const Text('Servicios', style: TextStyle(fontSize: 14)),

//               // --- PERSONALIZACIÓN DE ANIMACIÓN ---
//               expansionAnimationStyle: AnimationStyle(
//                 curve: Curves.fastOutSlowIn, // Entrada rápida, salida suave
//                 duration: const Duration(milliseconds: 500),
//               ),

//               // Animación del icono de la flecha
//               trailing: const Icon(Icons.expand_more),

//               children: [
//                 _buildSubItem(Icons.language, 'Web Design', '/web'),
//                 _buildSubItem(Icons.phone_android, 'Mobile App', '/mobile'),
//               ],
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   // Widget _buildSubItem(IconData icon, String label, String path) {
//   //   bool isSel = GoRouterState.of(context).uri.toString() == path;
//   //   return ListTile(
//   //     onTap: () => context.go(path),
//   //     dense: true,
//   //     leading: Icon(icon, size: 18, color: isSel ? Colors.indigo : null),
//   //     title: Text(
//   //       label,
//   //       style: TextStyle(fontSize: 13, color: isSel ? Colors.indigo : null),
//   //     ),
//   //     tileColor: isSel ? Colors.indigo.withOpacity(0.1) : null,
//   //   );
//   // }

//   Widget _buildSubItem(IconData icon, String label, String path) {
//     bool isSel = GoRouterState.of(context).uri.toString() == path;

//     return TweenAnimationBuilder<double>(
//       duration: const Duration(milliseconds: 400),
//       tween: Tween(begin: 0.0, end: 1.0),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: value,
//           child: Transform.translate(
//             offset: Offset(0, 10 * (1 - value)), // Desliza 10px hacia abajo
//             child: child,
//           ),
//         );
//       },
//       child: ListTile(
//         onTap: () => context.go(path),
//         dense: true,
//         leading: Icon(icon, size: 18, color: isSel ? Colors.indigo : null),
//         title: Text(
//           label,
//           style: TextStyle(fontSize: 13, color: isSel ? Colors.indigo : null),
//         ),
//         tileColor: isSel ? Colors.indigo.withOpacity(0.1) : null,
//       ),
//     );
//   }

//   Widget _buildSidebarFooter() {
//     return Expanded(
//       child: Align(
//         alignment: Alignment.bottomCenter,
//         child: SizedBox(
//           width: 260,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (_isRailFixed)
//                 SwitchListTile(
//                   title: const Text(
//                     'Dark Mode',
//                     style: TextStyle(fontSize: 11),
//                   ),
//                   value: themeNotifier.value == ThemeMode.dark,
//                   onChanged: (v) async {
//                     themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
//                     final prefs = await SharedPreferences.getInstance();
//                     prefs.setBool('isDarkMode', v);
//                     setState(() {});
//                   },
//                 ),
//               const ListTile(
//                 leading: CircleAvatar(child: Icon(Icons.person)),
//                 title: Text('Juan Pérez', style: TextStyle(fontSize: 13)),
//               ),
//               const SizedBox(height: 10),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       child: ListView(
//         children: [
//           const DrawerHeader(child: FlutterLogo()),
//           ListTile(
//             title: const Text('Dashboard'),
//             onTap: () => context.go('/'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSearchModal(BuildContext context) {
//     showDialog(
//       context: context,
//       builder:
//           (context) =>
//               AlertDialog(content: const Text('Buscador: Ctrl+K funciona!')),
//     );
//   }
// }

// // --- DASHBOARD ---
// class DashboardContent extends StatelessWidget {
//   const DashboardContent({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Dashboard',
//             style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 24),
//           GridView.count(
//             shrinkWrap: true,
//             crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
//             mainAxisSpacing: 20,
//             crossAxisSpacing: 20,
//             childAspectRatio: 2.5,
//             children: const [
//               Card(
//                 child: ListTile(
//                   title: Text('Ventas'),
//                   subtitle: Text('\$12,400'),
//                   leading: Icon(Icons.attach_money, color: Colors.green),
//                 ),
//               ),
//               Card(
//                 child: ListTile(
//                   title: Text('Usuarios'),
//                   subtitle: Text('1,120'),
//                   leading: Icon(Icons.person, color: Colors.blue),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 32),
//           Container(
//             height: 300,
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Theme.of(context).cardColor,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: LineChart(
//               LineChartData(
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: [
//                       const FlSpot(0, 1),
//                       const FlSpot(3, 4),
//                       const FlSpot(6, 3),
//                       const FlSpot(10, 7),
//                     ],
//                     isCurved: true,
//                     color: Colors.indigo,
//                     barWidth: 4,
//                   ),
//                 ],
//                 titlesData: const FlTitlesData(show: false),
//                 borderData: FlBorderData(show: false),
//                 gridData: const FlGridData(show: false),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'config/router.dart';
import 'config/theme.dart';

// // --- GESTIÓN DE ESTADO GLOBAL (Tema y Navegación) ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mi Web Flutter Pro',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter, // Importado de config/router.dart
      theme: appThemeLight, // Importado de config/theme.dart
      darkTheme: appThemeDark,
      themeMode: themeNotifier.value,
    );
  }
}
