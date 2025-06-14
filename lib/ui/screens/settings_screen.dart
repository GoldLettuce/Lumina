// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../widgets/advanced_mode_dialog.dart';
import '../widgets/deactivate_advanced_mode_dialog.dart';
import '../widgets/api_key_input_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _maskApiKey(String key) {
    if (key.length <= 3) return '*' * key.length;
    final tail = key.substring(key.length - 3);
    final stars = '*' * (key.length - 3);
    return '$stars$tail';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Spinner mientras cargamos prefs
    if (!settings.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final advanced = settings.advancedModeEnabled;
    final apiKey = settings.apiKey;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // Fila de activación/desactivación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Modo avanzado', style: TextStyle(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () async {
                    if (!advanced) {
                      // Diálogo de activación
                      final confirmed = await showAdvancedModeDialog(context);
                      if (confirmed != true) return;
                      await settings.setAdvancedMode(true);

                      // Diálogo de key
                      final key = await showApiKeyInputDialog(context);
                      if (key == null || key.isEmpty) {
                        // Revertir si no introduce
                        await settings.setAdvancedMode(false);
                        return;
                      }
                      await settings.setApiKey(key);
                    } else {
                      // Diálogo de desactivación
                      final deactivate =
                      await showDeactivateAdvancedModeDialog(context);
                      if (deactivate == true) {
                        await settings.setAdvancedMode(false);
                      }
                    }
                  },
                  child: Text(advanced ? 'Desactivar' : 'Activar'),
                ),
              ],
            ),
          ),

          // Contenedor de estado idéntico al diseño anterior
          if (advanced && apiKey != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Modo avanzado activado',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.vpn_key,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'API key guardada: ${_maskApiKey(apiKey)}',
                            style:
                            TextStyle(color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
