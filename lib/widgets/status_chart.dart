import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatusPieChart extends StatelessWidget {
  final int activos;
  final int pendientes;

  const StatusPieChart({
    super.key,
    required this.activos,
    required this.pendientes,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2, // Espacio entre rebanadas
        centerSpaceRadius: 40, // Radio del hueco central (estilo Donut)
        sections: [
          PieChartSectionData(
            value: activos.toDouble(),
            title: 'Activos',
            color: Colors.green,
            radius: 50,
            // textStyle: const TextStyle(
            //   fontSize: 12,
            //   fontWeight: FontWeight.bold,
            //   color: Colors.white,
            // ),
          ),
          PieChartSectionData(
            value: pendientes.toDouble(),
            title: 'Pendientes',
            color: Colors.orange,
            radius: 50,
            // textStyle: const TextStyle(
            //   fontSize: 12,
            //   fontWeight: FontWeight.bold,
            //   color: Colors.white,
            // ),
          ),
        ],
      ),
    );
  }
}
