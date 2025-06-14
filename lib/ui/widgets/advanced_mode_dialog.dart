// lib/ui/widgets/advanced_mode_dialog.dart

import 'package:flutter/material.dart';

Future<bool?> showAdvancedModeDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('¿Activar modo avanzado?'),
      content: SingleChildScrollView(
        child: ListBody(
          children: const [
            Text('Al activar esta opción podrás añadir nuevos tipos de activos:'),
            SizedBox(height: 12),
            Text('• Acciones (EE. UU., Europa, Asia)'),
            Text('• Índices bursátiles (S&P 500, IBEX 35…)'),
            Text('• Criptomonedas'),
            Text('• Divisas (Forex)'),
            Text('• ETFs'),
            Text('• Commodities (oro, petróleo…)'),
            SizedBox(height: 16),
            Text(
              '🔐 Necesitarás una API key gratuita de Finnhub para obtener los precios.',
            ),
            SizedBox(height: 8),
            Text(
              'Puedes crearla en: https://finnhub.io/',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Activar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
