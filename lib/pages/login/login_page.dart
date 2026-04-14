import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/app_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;

  void _handleLogin() async {
    final email = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      AppService.showAlert("Completa todos los campos");
      return;
    }

    // Usamos el loading global que ya definimos
    AppService.runWithLoading(() async {
      bool success = await AuthService.login(email, pass);

      if (success) {
        // await AppService.cargarUsuario();
        if (mounted) context.go('/'); // Redirige al Dashboard
      } else {
        AppService.showAlert("Email o contraseña incorrectos");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Icon(
              //   Icons.lock_person_rounded,
              //   size: 80,
              //   color: Colors.indigo,
              // ),
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/logo.png',
                  height: 120, // Ajusta el tamaño según tu diseño
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Bienvenido",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: "Usuario",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                      ),
                      const Text("Recuérdame", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  TextButton(
                    onPressed:
                        () => AppService.showAlert(
                          "Función de recuperación enviada al correo",
                        ),
                    child: const Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handleLogin(), // Pasamos el valor
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Iniciar Sesión"),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta?"),
                  TextButton(
                    onPressed:
                        () => context.go(
                          '/registro',
                        ), // Navegamos a la ruta de registro
                    child: const Text(
                      "Solicita acceso aquí",
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              // Opcional: Un divisor visual
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),

              TextButton.icon(
                onPressed:
                    () =>
                        AppService.showAlert("Función de recuperación enviada"),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
