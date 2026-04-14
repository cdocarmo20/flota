import 'package:cargasuy/models/usuario.dart';
import 'package:cargasuy/pages/admin_usuarios_page.dart';
import 'package:cargasuy/pages/cargas_disponibles_page.dart';
import 'package:cargasuy/pages/detalle_viaje_page.dart';
import 'package:cargasuy/pages/espera_page.dart';
import 'package:cargasuy/pages/flota_page.dart';
import 'package:cargasuy/pages/login/login_page.dart';
import 'package:cargasuy/pages/mis_cargas_aceptadas.dart';
import 'package:cargasuy/pages/mis_cargas_page.dart';
import 'package:cargasuy/pages/nuevo_transportista_page.dart';
import 'package:cargasuy/pages/placeholder_page.dart';
import 'package:cargasuy/pages/profile_page.dart';
import 'package:cargasuy/pages/solicitar_viaje_page.dart';
import 'package:cargasuy/pages/transportistas_page.dart';
import 'package:cargasuy/pages/login/perfil_usuario_page.dart';
import 'package:cargasuy/pages/login/register_page.dart';
import 'package:cargasuy/services/auth_service.dart';
import 'package:cargasuy/widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'wrapper.dart';
import 'pages/dashboard_page.dart';
import 'pages/clientes_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: Listenable.merge([isAuthenticated, userStatus]),
  redirect: (context, state) {
    final bool loggedIn = isAuthenticated.value;
    final String? status = userStatus.value;
    final bool isLoggingIn = state.matchedLocation == '/login';
    final bool isWaitingPage = state.matchedLocation == '/espera';

    final bool isRegistering = state.matchedLocation == '/registro';

    // 1. REGLA DE ORO: Si no está logueado y no está en login/registro, MANDAR A LOGIN
    if (!loggedIn) {
      return (isLoggingIn || isRegistering) ? null : '/login';
    }

    // 2. Si ya está logueado pero intenta ir al login o registro, MANDAR AL HOME
    if (isLoggingIn || isRegistering) {
      return '/';
    }

    // 3. Si está logueado pero su cuenta está PENDIENTE, mandarlo a espera
    // (Excepto si ya está en la página de espera)
    if (status == 'PENDIENTE' && state.matchedLocation != '/espera') {
      return '/espera';
    }

    // 4. Si ya está ACTIVO y sigue en espera, sacarlo de ahí
    if (status == 'ACTIVO' && state.matchedLocation == '/espera') {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/espera',
      builder: (context, state) => const PantallaEsperaPage(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroPage(),
    ),

    ShellRoute(
      builder: (context, state, child) => MainWrapper(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardPage()),

        // Esto Es un listado de clientes que no va mas
        // GoRoute(
        //   path: '/clientes',
        //   builder:
        //       (context, state) => const PageLayout(
        //         title: "Lista de Clientes ",
        //         icon: Icons.people,
        //         child: ClientesVIPPage(),
        //       ),
        // ),
        GoRoute(
          path: '/transportistas',
          builder:
              (context, state) => const PageLayout(
                title: "Lista de Transportistas ",
                icon: Icons.person_pin_outlined,
                child: TransportistasPage(),
              ),
        ),
        GoRoute(
          path: '/transportistas',
          builder: (context, state) => const TransportistasPage(),
        ),
        GoRoute(
          path: '/admin-usuarios',
          builder: (context, state) => const AdminUsuariosPage(),
          redirect:
              (context, state) => userRole.value != UserRole.admin ? '/' : null,
        ),
        GoRoute(
          path: '/flota',
          builder:
              (context, state) => const PageLayout(
                title: "Flota de Vehículos ",
                icon: Icons.local_shipping_rounded,
                child: FlotaPage(),
              ),
        ),

        GoRoute(
          path: '/solicitar-viaje',
          builder: (context, state) => const SolicitarViajePage(),
        ),

        // 2. Ruta para que el Cliente vea el historial de sus pedidos
        GoRoute(
          path: '/mis-viajes',
          builder: (context, state) => const MisCargasPage(),
        ),

        // 3. Ruta para que el Transportista vea cargas para aceptar
        GoRoute(
          path: '/cargas-disponibles',
          builder: (context, state) => const CargasDisponiblesPage(),
        ),
        GoRoute(
          path: '/cargas-aceptadas',
          builder: (context, state) => const MisViajesAceptadosPage(),
        ),

        GoRoute(
          path: '/nuevo-transportista',
          builder: (context, state) => const NuevoTransportistaPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Center(child: Text("Ajustes")),
        ),
        GoRoute(
          path: '/mi-perfil',
          builder: (context, state) => const PerfilUsuarioPage(),
        ),

        GoRoute(
          path: '/detalle-viaje/:viajeId', // El ':' indica que es un parámetro
          builder: (context, state) {
            // Extraemos el ID de la URL
            final viajeId = state.pathParameters['viajeId']!;
            return DetalleViajePage(viajeId: viajeId);
          },
        ),

        GoRoute(
          path: '/profile',
          builder:
              (context, state) => const PageLayout(
                title: "Mi Perfil ",
                icon: Icons.account_circle_rounded,
                child: ProfilePage(),
              ),

          // (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);

//  GoRoute(path: '/clientes-vip', builder: (context, state) => 
//           const PlaceholderPage(title: "Lista de Clientes VIP", icon: Icons.stars)),
          