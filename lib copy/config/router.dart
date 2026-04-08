import 'package:demos/features/auth/auth_service.dart';
import 'package:demos/features/auth/login_page.dart';
import 'package:demos/layout/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Importa tus páginas aquí
import '../features/dashboard/dashboard_page.dart';
import '../layout/responsive_layout.dart';

final ValueNotifier<bool> isNavigatingNotifier = ValueNotifier(false);
final authService = AuthService();

final goRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authService, // Escucha cambios de login/logout
  redirect: (context, state) {
    final bool loggingIn = state.matchedLocation == '/login';
    if (!authService.isLoggedIn) return loggingIn ? null : '/login';
    if (loggingIn) return '/'; // Si ya está logueado, no puede ir al login
    return null;
  },
  routes: [
    // ShellRoute(
    //   builder: (context, state, child) => ResponsiveMainScreen(child: child),
    //   routes: [
    ShellRoute(
      builder: (context, state, child) => ResponsiveMainScreen(child: child),
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            // isNavigatingNotifier.value = true;
            return CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
              transitionsBuilder:
                  (context, anim, secAnim, child) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
            );
          },
        ),
        GoRoute(
          path: '/config',
          pageBuilder: (context, state) {
            // isNavigatingNotifier.value = true;
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Center(child: Text('Ajustes')),
              transitionsBuilder:
                  (context, anim, secAnim, child) =>
                      FadeTransition(opacity: anim, child: child),
            );
          },
        ),
      ],
    ),
    //   ],
    // ),
  ],
);

// final goRouter = GoRouter(
//   initialLocation: '/',
//   refreshListenable: authService, // Escucha cambios de login/logout
//   redirect: (context, state) {
//     final bool loggingIn = state.matchedLocation == '/login';
//     if (!authService.isLoggedIn) return loggingIn ? null : '/login';
//     if (loggingIn) return '/'; // Si ya está logueado, no puede ir al login
//     return null;
//   },
//   routes: [
//     GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
//     ShellRoute(
//       builder: (context, state, child) => ResponsiveMainScreen(child: child),
//       routes: [
//         GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
//         // ... otras rutas protegidas
//       ],
//     ),
//   ],
// );
