import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'csv_export_service.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import '../l10n/app_localizations.dart';

class ExportController {
  static Future<void> handleCsvExport(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final status = await Permission.manageExternalStorage.status;

    if (status.isDenied) {
      final result = await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.permissionRequiredForFile),
            ),
          );
        }
        return;
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.permissionPermanentlyDenied),
            action: SnackBarAction(
              label: t.openSettings,
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return;
    }

    try {
      // ignore: use_build_context_synchronously
      final investments = context.read<InvestmentProvider>().investments;
      debugPrint(
        '📤 Iniciando exportación de ${investments.length} inversiones...',
      );
      final path = await CsvExportService().export(investments);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.fileSavedSuccess(path))));
      }
    } catch (e) {
      debugPrint('❌ Error al exportar archivo CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.exportFileError)),
        );
      }
    }
  }
}
