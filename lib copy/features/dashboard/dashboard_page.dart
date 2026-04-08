import 'package:demos/config/app_services.dart';
import 'package:demos/features/dashboard/widgets/sales_chart.dart';
import 'package:flutter/material.dart';
// import '../services/loading_service.dart';
// import '../widgets/sales_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    await LoadingService.run(() async {
      await Future.delayed(const Duration(seconds: 2)); // Simula latencia
      if (mounted) setState(() => _dataLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded)
      return const SizedBox.shrink(); // El spinner global ya se ve

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resumen de Ventas",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Contenedor del gráfico con estilo moderno
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: const SalesChart(),
          ),
        ],
      ),
    );
  }
}
