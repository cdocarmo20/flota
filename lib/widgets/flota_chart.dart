import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FlotaChart extends StatelessWidget {
  final Map<String, double> datos;

  const FlotaChart({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    datos.forEach((nombre, capacidad) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: capacidad,
              color: Colors.indigo,
              width: 25,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100, // Ajusta según tus capacidades máximas
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Muestra la primera letra o nombre corto del transportista
                String nombre = datos.keys.elementAt(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    nombre.substring(0, 3).toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
