import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'csv_export_service.dart';
import 'csv_import_service.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
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
    try {
      final file = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (file == null) return;

      final investments = await CsvImportService.parseCsv(File(file.files.single.path!));
      
      if (!context.mounted) return;
      
      final invProv = context.read<InvestmentProvider>();
      for (final inv in investments) {
        await invProv.addInvestment(inv);
      }

      if (!context.mounted) return;

      // [IMPORT_FIX] Refrescar precios inmediatamente tras importar
      final spot = context.read<SpotPriceProvider>();
      // Si tu provider ya tiene auto-refresh, solo fuerza un ciclo:
      await spot.loadPrices(); // carga con mapping actual; el resto lo hará el ciclo

      if (!context.mounted) return;

      // Si esta acción viene de una ruta modal, notificar cambio al padre:
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }

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
