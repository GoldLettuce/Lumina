// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/advanced_mode_dialog.dart';
import '../widgets/deactivate_advanced_mode_dialog.dart';
import '../widgets/api_key_input_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _advancedModeEnabled = false;
  String? _apiKey;
  bool _isLoading = true;
  bool _isAskingForKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _advancedModeEnabled = prefs.getBool('advanced_mode_enabled') ?? false;
      _apiKey = prefs.getString('finnhub_api_key');
      _isLoading = false;
    });
  }

  Future<void> _setAdvancedMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advanced_mode_enabled', enabled);
    setState(() {
      _advancedModeEnabled = enabled;
      if (!enabled) _apiKey = null;
    });
  }

  Future<void> _setApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null) {
      await prefs.remove('finnhub_api_key');
    } else {
      await prefs.setString('finnhub_api_key', key);
    }
    setState(() {
      _apiKey = key;
    });
  }

  String _maskApiKey(String key) {
    if (key.length <= 3) {
      // Si tiene 3 o menos, ocultamos todo
      return '*' * key.length;
    }
    final tail = key.substring(key.length - 3);      // Últimos 3
    final stars = '*' * (key.length - 3);            // El resto en asteriscos
    return '$stars$tail';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // Fila de modo avanzado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Modo avanzado', style: TextStyle(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () async {
                    if (!_advancedModeEnabled) {
                      // 1) Confirmar activación
                      final confirmed = await showAdvancedModeDialog(context);
                      if (confirmed == true) {
                        // 2) Activar temporalmente
                        await _setAdvancedMode(true);

                        // 3) Pedir API key
                        setState(() => _isAskingForKey = true);
                        final apiKey = await showApiKeyInputDialog(context);
                        setState(() => _isAskingForKey = false);

                        // 4) Si no introduce key, revertir
                        if (apiKey == null || apiKey.isEmpty) {
                          await _setAdvancedMode(false);
                          return;
                        }

                        // 5) Guardar API key
                        await _setApiKey(apiKey);
                      }
                    } else {
                      // Confirmar desactivación
                      final deactivate =
                      await showDeactivateAdvancedModeDialog(context);
                      if (deactivate == true) {
                        await _setAdvancedMode(false);
                      }
                    }
                  },
                  child: Text(_advancedModeEnabled ? 'Desactivar' : 'Activar'),
                ),
              ],
            ),
          ),

          // Estado de la API key (solo cuando está activo y no estamos en diálogo)
          if (_advancedModeEnabled && !_isAskingForKey && _apiKey != null)
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
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 6),
                        Text('Modo avanzado activado',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.vpn_key, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'API key guardada: ${_maskApiKey(_apiKey!)}',
                            style: TextStyle(color: Colors.grey.shade700),
                            // Ya no necesitamos ellipsis porque la longitud es constante
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
