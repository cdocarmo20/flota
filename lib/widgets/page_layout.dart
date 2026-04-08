import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child; // Aquí irá el contenido de cada página
  final List<Widget>? actions; // Botones opcionales a la derecha

  const PageLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent, // El fondo lo da el Wrapper
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ENCABEZADO DINÁMICO
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Gestión y administración de $title",
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 32),

            // 2. CUERPO DE LA PÁGINA (TARJETA DE CONTENIDO)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
