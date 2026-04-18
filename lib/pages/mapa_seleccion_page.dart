import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class MapaSeleccionPage extends StatefulWidget {
  final gmaps.LatLng posicionInicial; // La ciudad elegida en el Dropdown

  const MapaSeleccionPage({super.key, required this.posicionInicial});

  @override
  State<MapaSeleccionPage> createState() => _MapaSeleccionPageState();
}

class _MapaSeleccionPageState extends State<MapaSeleccionPage> {
  late gmaps.LatLng _ubicacionSeleccionada;
  late gmaps.GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    // Empezamos en el centro de la ciudad elegida
    _ubicacionSeleccionada = widget.posicionInicial;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ubicar en Mapa", style: TextStyle(fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context), // Cierra sin devolver nada
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(_ubicacionSeleccionada);
                }
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop<gmaps.LatLng>(_ubicacionSeleccionada);
                // Navigator.of(context, rootNavigator: true).pop(_ubicacionSeleccionada);
              },
              // onPressed: () => Navigator.pop(context, _ubicacionSeleccionada),
              child: const Text(
                "CONFIRMAR",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: _ubicacionSeleccionada,
                zoom: 15,
              ),
              onCameraMove: (pos) => _ubicacionSeleccionada = pos.target,
              myLocationEnabled: true,
            ),
            const Center(
              child: Icon(Icons.location_on, size: 40, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
