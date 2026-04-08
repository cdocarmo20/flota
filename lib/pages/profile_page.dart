import 'package:flutter/material.dart';
import '../widgets/page_layout.dart';
import '../services/app_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: "Admin User");
  final _emailController = TextEditingController(text: "admin@tuweb.com");

  final _passController = TextEditingController();
  final _newPassController = TextEditingController();

  void _updateProfile() {
    AppService.runWithLoading(() async {
      await Future.delayed(const Duration(seconds: 1));
      AppService.showAlert("Datos actualizados correctamente");
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSectionTitle("Información Personal"),
              const SizedBox(height: 20),
              _buildTextField("Nombre Completo", _nameController, Icons.person),
              const SizedBox(height: 16),
              _buildTextField(
                "Correo Electrónico",
                _emailController,
                Icons.email,
              ),

              const SizedBox(height: 40),
              _buildSectionTitle("Seguridad y Contraseña"),
              const SizedBox(height: 20),
              _buildTextField(
                "Contraseña Actual",
                _passController,
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Nueva Contraseña",
                _newPassController,
                Icons.key_rounded,
                isPassword: true,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Guardar Cambios"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return SizedBox(
      width: 500,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
