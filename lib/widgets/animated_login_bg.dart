import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedLoginBackground extends StatefulWidget {
  final Widget child;
  const AnimatedLoginBackground({super.key, required this.child});

  @override
  State<AnimatedLoginBackground> createState() =>
      _AnimatedLoginBackgroundState();
}

class _AnimatedLoginBackgroundState extends State<AnimatedLoginBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Controlamos la velocidad del movimiento (15 segundos para una vuelta completa)
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. FONDO DEGRADADO ANIMADO
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // Los colores van rotando según el valor del controlador
                  colors: const [
                    Color(0xFF1E1B4B), // Indigo muy oscuro
                    Color(0xFF312E81), // Indigo medio
                    Color(0xFF4338CA), // Indigo vibrante
                  ],
                  transform: GradientRotation(_controller.value * 2 * math.pi),
                ),
              ),
            );
          },
        ),

        // 2. PARTÍCULAS DECORATIVAS (Círculos difusos)
        _buildBlurryCircle(
          top: -50,
          left: -50,
          size: 300,
          color: Colors.indigoAccent,
        ),
        _buildBlurryCircle(
          bottom: -100,
          right: -50,
          size: 400,
          color: Colors.deepPurple,
        ),

        // 3. EL CONTENIDO (Tu formulario de Login o Registro)
        SafeArea(child: widget.child),
      ],
    );
  }

  // Helper para crear los círculos de fondo
  Widget _buildBlurryCircle({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Opacity(
        opacity: 0.15,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
            ],
          ),
        ),
      ),
    );
  }
}
