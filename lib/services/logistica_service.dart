// En lib/services/logistica_service.dart o dentro de tu Dashboard
import 'package:demos/models/transportista.dart';
import 'package:demos/models/vehiculo.dart';

class LogisticaService {
  static Map<String, double> calcularCapacidadPorTransportista(
    List<Transportista> lista,
  ) {
    Map<String, double> mapa = {};

    for (var t in lista) {
      double total = 0;
      for (var v in t.vehiculos) {
        // Usamos la función de extracción de números que definimos antes
        total += _extraerNumero(v.capacidad);
      }
      mapa[t.nombre] = total;
    }
    return mapa;
  }

  static double calcularPromedioModelo(List<Vehiculo> vehiculos) {
    if (vehiculos.isEmpty) return 0;
    // Extraemos el año (ej: "2022") y sumamos
    double sumaAnios = vehiculos.fold(0, (acc, v) {
      return acc +
          (double.tryParse(RegExp(r'\d{4}').stringMatch(v.modelo) ?? '0') ?? 0);
    });
    return sumaAnios / vehiculos.length;
  }

  static double _extraerNumero(String texto) {
    final RegExp regExp = RegExp(r"(\d+(\.\d+)?)");
    final match = regExp.firstMatch(texto);
    return match != null ? double.parse(match.group(0)!) : 0.0;
  }
}
