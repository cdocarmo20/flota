import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/router.dart';

class ResponsiveMainScreen extends StatefulWidget {
  final Widget child;
  const ResponsiveMainScreen({super.key, required this.child});

  @override
  State<ResponsiveMainScreen> createState() => _ResponsiveMainScreenState();
}

class _ResponsiveMainScreenState extends State<ResponsiveMainScreen> {
  bool _isRailFixed = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isRailFixed = prefs.getBool('isRailFixed') ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Fijo/Colapsable
          _buildSidebar(),
          const VerticalDivider(width: 1),
          // Contenido con Barra de Carga Superior
          Expanded(
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: isNavigatingNotifier,
                  builder:
                      (context, isNavigating, _) =>
                          isNavigating
                              ? const LinearProgressIndicator(minHeight: 3)
                              : const SizedBox(height: 3),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isRailFixed ? 260 : 80,
      child: NavigationRail(
        extended: _isRailFixed,
        selectedIndex: _calculateIndex(context),
        leading: IconButton(
          icon: Icon(_isRailFixed ? Icons.menu_open : Icons.menu),
          onPressed: () => setState(() => _isRailFixed = !_isRailFixed),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings),
            label: Text('Ajustes'),
          ),
        ],
        onDestinationSelected: (i) => _onNav(i),
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/config') return 1;
    return 0;
  }

  void _onNav(int i) {
    if (i == 0) context.go('/');
    if (i == 1) context.go('/config');
  }
}
