import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        barGroups: [
          _makeGroup(0, 12, Colors.blue),
          _makeGroup(1, 15, Colors.indigo),
          _makeGroup(2, 8, Colors.purple),
          _makeGroup(3, 18, Colors.cyan),
        ],
        titlesData: const FlTitlesData(show: true), // Personalizable
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
