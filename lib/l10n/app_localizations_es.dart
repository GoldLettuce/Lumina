// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mi Portafolio';

  @override
  String get dailyPL => 'P/G diario | 0,00 € 0.00%';

  @override
  String get openPL => 'Abrir P/G | 4,328.47 € 1.17%';

  @override
  String get graphPlaceholder => 'Marcador de gráfico';

  @override
  String get quantity => 'Cantidad';

  @override
  String get noInvestments => 'No hay inversiones';
}
