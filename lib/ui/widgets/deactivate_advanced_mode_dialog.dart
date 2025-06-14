import 'package:flutter/material.dart';

Future<bool?> showDeactivateAdvancedModeDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Desactivar modo avanzado?'),
      content: SingleChildScrollView(
        child: ListBody(
          children: const [
            Text('Al desactivar el modo avanzado, perderás acceso a los siguientes activos:'),
            SizedBox(height: 12),
            Text('• Acciones (EE. UU., Europa, Asia)'),
            Text('• Índices bursátiles (S&P 500, IBEX 35...)'),
            Text('• Criptomonedas'),
            Text('• Divisas (Forex)'),
            Text('• ETFs'),
            Text('• Materias primas (oro, petróleo...)'),
            SizedBox(height: 16),
            Text(
              'Todos los activos avanzados en tu portafolio serán ocultados.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('¿Estás seguro que quieres continuar?'),
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
          child: const Text('Desactivar'),
        ),
      ],
    ),
  );
}
