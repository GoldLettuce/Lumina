// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Portfolio';

  @override
  String get dailyPL => 'Daily P/L | 0.00 € 0.00%';

  @override
  String get openPL => 'Open P/L | 4,328.47 € 1.17%';

  @override
  String get graphPlaceholder => 'Graph placeholder';

  @override
  String get quantity => 'Quantity';
}
