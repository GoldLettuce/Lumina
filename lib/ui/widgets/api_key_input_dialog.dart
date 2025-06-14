import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> showApiKeyInputDialog(BuildContext context) {
  final controller = TextEditingController();
  bool _validating = false;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Introduce tu API key de Finnhub'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Puedes crear una cuenta gratuita en:\nhttps://finnhub.io\n\nCopia aquí tu API key para activar la conexión.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_validating) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                'Lo haré después',
                style: TextStyle(color: Color(0xFF444444)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final key = controller.text.trim();
                if (key.isEmpty) return;

                setState(() => _validating = true);

                final isValid = await validateFinnhubApiKey(key);

                setState(() => _validating = false);

                if (isValid) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('finnhub_api_key', key);

                  Navigator.of(context).pop(key);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API key inválida. Verifica y vuelve a intentarlo.'),
                    ),
                  );
                }
              },
              child: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> validateFinnhubApiKey(String apiKey) async {
  final url = Uri.parse('https://finnhub.io/api/v1/stock/symbol?exchange=US&token=$apiKey');
  try {
    final response = await http.get(url);
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
