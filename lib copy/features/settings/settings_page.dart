import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../main.dart'; // Para acceder al themeNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Español';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // --- SECCIÓN APARIENCIA ---
          _buildSectionTitle('Apariencia'),
          Card(
            child: Column(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Modo Oscuro'),
                      subtitle: const Text(
                        'Cambia el tema visual de la aplicación',
                      ),
                      value: mode == ThemeMode.dark,
                      onChanged: (value) {
                        themeNotifier.value =
                            value ? ThemeMode.dark : ThemeMode.light;
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- SECCIÓN GENERAL ---
          _buildSectionTitle('General'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Idioma'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(),
                ),
                const Divider(height: 1, indent: 55),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none_outlined),
                  title: const Text('Notificaciones Push'),
                  subtitle: const Text('Recibir alertas de actualizaciones'),
                  value: _notificationsEnabled,
                  onChanged:
                      (value) => setState(() => _notificationsEnabled = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- SECCIÓN CUENTA ---
          _buildSectionTitle('Cuenta'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                // Lógica de logout
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar Idioma'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['Español', 'English', 'Français'].map((lang) {
                    return RadioListTile<String>(
                      title: Text(lang),
                      value: lang,
                      groupValue: _selectedLanguage,
                      onChanged: (val) {
                        setState(() => _selectedLanguage = val!);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }
}
