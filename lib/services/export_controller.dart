import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'csv_export_service.dart';
import 'csv_import_service.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import '../l10n/app_localizations.dart';

// Si usas un wrapper de SnackBar propio, impórtalo; si no, usa ScaffoldMessenger directamente.
void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class ExportController {
  static Future<void> handleCsvExport(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    try {
      // 1) Obtener inversiones desde el provider (ajusta getter si difiere)
      final investments = context.read<InvestmentProvider>().investments;
      if (investments.isEmpty) {
        _showSnack(context, t.noInvestments); // o texto plano: "No hay inversiones"
        return;
      }

      // 2) Generar CSV en /tmp
      final path = await CsvExportService.saveTempCsv(investments);

      // 3) Abrir share sheet (iOS/Android)
      await Share.shareXFiles(
        [XFile(path, mimeType: 'text/csv', name: 'operaciones_lumina.csv')],
        subject: t.exportOperationsToCsv,
        text: t.exportOperationsToCsv,
      );
      // opcional: _showSnack(context, t.exportDone);
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, t.exportFileError); // o texto plano
      }
    }
  }

  static Future<void> handleCsvImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null) return; // cancelado

    try {
      final file = File(result.files.single.path!);
      final investments = await CsvImportService.parseCsv(file);

      if (!context.mounted) return;

      final provider = context.read<InvestmentProvider>();
      for (final inv in investments) {
        // Add the investment if it doesn't exist
        await provider.addInvestment(inv);
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importación completada ✅')),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e')),
      );
    }
  }
}
