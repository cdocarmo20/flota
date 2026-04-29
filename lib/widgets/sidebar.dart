import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_state.dart';

final ValueNotifier<bool> isSidebarExpanded = ValueNotifier(true);

class CustomSidebar extends StatelessWidget {
  const CustomSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: isSidebarExpanded,
      builder: (context, isExpanded, _) {
        return ValueListenableBuilder<UserRole?>(
          valueListenable: userRole,
          builder: (context, rol, _) {
            if (isAuthenticated.value && rol == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? 260 : 80,
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  // Botón para colapsar/expandir
                  IconButton(
                    icon: Icon(isExpanded ? Icons.menu_open : Icons.menu),
                    onPressed:
                        () =>
                            isSidebarExpanded.value = !isSidebarExpanded.value,
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 1. Ítem Simple
                          _navItem(
                            context,
                            Icons.dashboard,
                            "Inicio",
                            "/",
                            isExpanded,
                          ),
                          const Divider(
                            height: 20, // Espacio total que ocupa el separador
                            thickness: 1, // Grosor de la línea
                            indent: 15, // Espacio desde la izquierda
                            endIndent: 15, // Espacio desde la derecha
                            color:
                                Colors
                                    .grey, // Puedes usar Theme.of(context).dividerColor
                          ),
                          if (rol != UserRole.admin) ...[
                            // if (rol == UserRole.cliente) ...[
                            // const Padding(
                            //   padding: EdgeInsets.only(left: 16, top: 10, bottom: 2),
                            //   child: Text(
                            //     "ADMINISTRACIÓN",
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.bold,
                            //       color: Colors.grey,
                            //       letterSpacing: 1.2,
                            //     ),
                            //   ),
                            // ),
                            _navItem(
                              context,
                              Icons.local_mall,
                              "Cargas Disponibles",
                              "/cargas-disponibles",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.search,
                              "Vehículos Disponibles",
                              "/vehiculos-disponibles",
                              isExpanded,
                            ),

                            const Divider(
                              height:
                                  20, // Espacio total que ocupa el separador
                              thickness: 1, // Grosor de la línea
                              indent: 15, // Espacio desde la izquierda
                              endIndent: 15, // Espacio desde la derecha
                              color:
                                  Colors
                                      .grey, // Puedes usar Theme.of(context).dividerColor
                            ),

                            _navItem(
                              context,
                              Icons.add_road,
                              "Publicar Carga",
                              "/solicitar-viaje",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.reorder,
                              "Mis Cargas Publicadas",
                              "/mis-viajes",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.checklist_outlined,
                              "Mis Cargas Aceptadas",
                              "/cargas-aceptadas",
                              isExpanded,
                            ),
                            const Divider(
                              height:
                                  20, // Espacio total que ocupa el separador
                              thickness: 1, // Grosor de la línea
                              indent: 15, // Espacio desde la izquierda
                              endIndent: 15, // Espacio desde la derecha
                              color:
                                  Colors
                                      .grey, // Puedes usar Theme.of(context).dividerColor
                            ),

                            _navItem(
                              context,
                              Icons.airport_shuttle_outlined,
                              "Publicar Vehículos",
                              "/publicar-vehiculo",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.reorder,
                              "Mis Vehículos Publicados",
                              "/mis-vehiculos-publicados",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.checklist_outlined,
                              "Mis Vehículos Solicitados",
                              "/mis-vehiculos-solicitados",
                              isExpanded,
                            ),
                            const Divider(
                              height:
                                  20, // Espacio total que ocupa el separador
                              thickness: 1, // Grosor de la línea
                              indent: 15, // Espacio desde la izquierda
                              endIndent: 15, // Espacio desde la derecha
                              color:
                                  Colors
                                      .grey, // Puedes usar Theme.of(context).dividerColor
                            ),
                            // ],
                            // if (rol == UserRole.transportista) ...[
                            _navItem(
                              context,
                              Icons.local_shipping_rounded,
                              "Mi Flota",
                              "/flota",
                              isExpanded,
                            ),
                          ],
                          // ],
                          if (rol == UserRole.admin) ...[
                            _navItem(
                              context,
                              Icons.people,
                              "Clientes(Usuarios)",
                              "/admin-usuarios",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.person_pin_outlined,
                              "Transportistas",
                              "/transportistas",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.local_shipping_rounded,
                              "Flota",
                              "/flota",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.alternate_email,
                              "Mis Viajes",
                              "/mis-viajes",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.add_road,
                              "Publicar Carga",
                              "/solicitar-viaje",
                              isExpanded,
                            ),
                            _navItem(
                              context,
                              Icons.local_mall,
                              "Cargas Disponibles",
                              "/cargas-disponibles",
                              isExpanded,
                            ),

                            _navItem(
                              context,
                              Icons.airplane_ticket_outlined,
                              "Mis Cargas Aceptadas",
                              "/cargas-aceptadas",
                              isExpanded,
                            ),
                            // 2. ÍTEM CON SUBMENÚ (Uso de ExpansionTile)
                            if (isExpanded)
                              Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  leading: const Icon(Icons.analytics),
                                  title: const Text(
                                    "Reportes",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  children: [
                                    _subNavItem(
                                      context,
                                      "Ventas Diarias",
                                      "/ventas",
                                    ),
                                    _subNavItem(
                                      context,
                                      "Stock Actual",
                                      "/stock",
                                    ),
                                  ],
                                ),
                              )
                            else
                              // Si está colapsado, mostramos solo el icono principal
                              _navItem(
                                context,
                                Icons.analytics,
                                "Reportes",
                                "/ventas",
                                false,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3. Otro Ítem Simple
                  _buildThemeToggle(isExpanded),
                  // const SizedBox(height: 20),
                  const Divider(),
                  if (isExpanded)
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            leading: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                            ),
                            title: const Text("Cerrar Sesión"),
                            onTap: () async {
                              await AuthService.logout();
                              if (context.mounted) context.go('/login');
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.manage_accounts_outlined),
                          onPressed: () => context.go("/mi-perfil"),
                        ),
                        const SizedBox(width: 8),
                      ],
                    )
                  else
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.manage_accounts_outlined),
                          onPressed: () => context.go("/mi-perfil"),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            await AuthService.logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget para ítems principales
  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    String path,
    bool isExp,
  ) {
    final bool isSel = GoRouterState.of(context).uri.toString() == path;
    return ListTile(
      leading: Icon(icon, color: isSel ? Colors.indigo : null),
      title: isExp ? Text(label, style: const TextStyle(fontSize: 14)) : null,
      onTap: () => context.go(path),
    );
  }

  // Widget para los hijos del submenú
  Widget _subNavItem(BuildContext context, String label, String path) {
    final bool isSel = GoRouterState.of(context).uri.toString() == path;
    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 40,
      ), // Indentación para que se vea como submenú
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSel ? Colors.indigo : Colors.grey,
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      dense: true,
      onTap: () => context.go(path),
    );
  }

  Widget _buildThemeToggle(bool isExpanded) {
    return IconButton(
      icon: const Icon(Icons.brightness_6),
      onPressed: () => AppService.toggleTheme(),
    );
  }
}
