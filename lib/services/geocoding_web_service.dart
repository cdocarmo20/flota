import 'package:google_maps/google_maps.dart' as gm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as flutter_maps;

class GeocodingWebService {
  static Future<String> obtenerDireccion(flutter_maps.LatLng coords) async {
    final geocoder = gm.Geocoder();

    // Convertimos el LatLng de flutter_maps al LatLng de google_maps (JS)
    final request =
        gm.GeocoderRequest()
          ..location = gm.LatLng(coords.latitude, coords.longitude);

    try {
      final response = await geocoder.geocode(request);

      if (response.results != null && response.results!.isNotEmpty) {
        // Retorna la dirección formateada del primer resultado
        return response.results!.first?.formattedAddress ??
            "Dirección sin nombre";
      }
      return "No se encontraron resultados";
    } catch (e) {
      return "Error en geocoding: $e";
    }
  }
}
