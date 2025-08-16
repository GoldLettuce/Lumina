import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'csv_export_service.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/widgets/app_snack.dart';

class ExportController {
  static Future<void> handleCsvExport(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final status = await Permission.manageExternalStorage.status;

    if (status.isDenied) {
      final result = await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        if (context.mounted) {
          showAppSnack(
            context,
            message: t.permissionRequiredForFile,
            kind: AppSnackKind.error,
          );
        }
        return;
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        showAppSnack(
          context,
          message: t.permissionPermanentlyDenied,
          kind: AppSnackKind.error,
        );
      }
      return;
    }

    try {
      // ignore: use_build_context_synchronously
      final investments = context.read<InvestmentProvider>().investments;

      final path = await CsvExportService().export(investments);
      if (context.mounted) {
        showAppSnack(
          context,
          message: t.fileSavedSuccess(path),
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {

      if (context.mounted) {
        showAppSnack(
          context,
          message: t.exportFileError,
          kind: AppSnackKind.error,
        );
      }
    }
  }
}
