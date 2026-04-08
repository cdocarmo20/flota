import 'package:flutter/material.dart';

class PantallaEsperaPage extends StatelessWidget {
  const PantallaEsperaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 80, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              "Cuenta en Revisión",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Un administrador verificará tus datos pronto. Te notificaremos por mail.",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
