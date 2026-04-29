import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
    // _navigateToHome();
  }

  // _navigateToHome() async {
  //   // Esperamos 3 segundos para que se vea el logo
  //   await Future.delayed(const Duration(seconds: 3));

  //   if (mounted) {
  //     // Usamos go para que el usuario no pueda volver atrás al splash
  //     context.go('/mis-viajes');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // Usamos un fondo oscuro para que el logo blanco resalte
      backgroundColor: Theme.of(context).cardColor,
      body: Center(
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 1500),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Asegúrate de tener el logo en tus assets
              Image.asset(
                isDark ? 'assets/logo.png' : 'assets/logon.png',
                width: 250,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dentro de _SplashPageState
  _checkAuthAndNavigate() async {
    // 1. Espera mínima para que se vea tu logo
    await Future.delayed(const Duration(seconds: 2));

    // 2. Verificar sesión (ejemplo con Supabase)
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      // Si hay usuario, vamos al Dashboard (que tiene la barra lateral)
      context.go('/');
    } else {
      // Si no hay usuario, vamos al Login (pantalla completa)
      context.go('/login');
    }
  }
}
