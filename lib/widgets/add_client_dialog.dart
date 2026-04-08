import 'package:flutter/material.dart';

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({super.key});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  // La llave para controlar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar el texto
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Nuevo Cliente VIP"),
      content: Form(
        key: _formKey, // Asignamos la llave
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CAMPO NOMBRE
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre Completo",
                icon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return "El nombre es obligatorio";
                return null;
              },
            ),
            const SizedBox(height: 16),
            // CAMPO EMAIL
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: "Correo Electrónico",
                icon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@'))
                  return "Introduce un email válido";
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text("Guardar Cliente"),
        ),
      ],
    );
  }

  void _submit() {
    // Si la validación pasa...
    if (_formKey.currentState!.validate()) {
      // Devolvemos los datos al cerrar el modal
      Navigator.pop(context, {
        "nombre": _nombreCtrl.text,
        "email": _emailCtrl.text,
        "status": "Activo",
      });
    }
  }
}
