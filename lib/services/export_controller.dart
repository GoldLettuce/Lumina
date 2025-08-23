import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_export_service.dart';
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
      debugPrint('❌ Error exportando CSV: $e');
      if (context.mounted) {
        _showSnack(context, t.exportFileError); // o texto plano
      }
    }
  }
}
