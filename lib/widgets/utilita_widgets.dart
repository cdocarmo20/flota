import 'package:flutter/material.dart';

class UtilitaWidgets {
  Widget buildInput3(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool caps = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? "Requerido" : null,
    );
  }

  Widget buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (v) => v!.isEmpty ? "Este campo es obligatorio" : null,
    );
  }

  Widget buildStatusBadge(String texto, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Fondo clarito
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2), // Borde sólido
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBotonAccion({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget buildInput2(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType:
            isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          // Bordes redondeados modernos
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget buildDropdownLocalidad(
    String label,
    String? valorActual,
    List<Map<String, dynamic>> _localidades,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: valorActual,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.location_city, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        items:
            _localidades.map((loc) {
              return DropdownMenuItem<String>(
                value:
                    loc['id']
                        .toString(), // El UUID que espera tu tabla 'viajes'
                child: Text(loc['nombre']),
              );
            }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Selecciona una ciudad" : null,
      ),
    );
  }
}
