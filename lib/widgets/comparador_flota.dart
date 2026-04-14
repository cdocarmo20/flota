import 'package:cargasuy/models/transportista.dart';
import 'package:cargasuy/services/logistica_service.dart';
import 'package:flutter/material.dart';

Widget buildComparador(Transportista t1, Transportista t2) {
  double prom1 = LogisticaService.calcularPromedioModelo(t1.vehiculos);
  double prom2 = LogisticaService.calcularPromedioModelo(t2.vehiculos);

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _columnaComparativa(t1.nombre, prom1, prom1 >= prom2),
      const Text(
        "VS",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
      _columnaComparativa(t2.nombre, prom2, prom2 >= prom1),
    ],
  );
}

Widget _columnaComparativa(String nombre, double promedio, bool esGanador) {
  return Column(
    children: [
      Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              esGanador
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: esGanador ? Colors.green : Colors.grey),
        ),
        child: Column(
          children: [
            const Text("Modelo Promedio", style: TextStyle(fontSize: 10)),
            Text(
              promedio.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: esGanador ? Colors.green : null,
              ),
            ),
            if (esGanador)
              const Icon(Icons.verified, color: Colors.green, size: 16),
          ],
        ),
      ),
    ],
  );
}
