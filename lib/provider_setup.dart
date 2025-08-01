import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:lumina/ui/providers/app_initialization_provider.dart';
import 'package:lumina/ui/providers/settings_provider.dart';
import 'package:lumina/ui/providers/locale_provider.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import 'package:lumina/ui/providers/asset_list_provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/providers/profit_display_mode_notifier.dart';
import 'package:lumina/ui/providers/theme_mode_provider.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';

/// Configuración centralizada de todos los providers de la aplicación
List<SingleChildWidget> buildAppProviders() {
  return [
    ChangeNotifierProvider(create: (_) => AppInitializationProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider(create: (_) => CurrencyProvider()),
    ChangeNotifierProvider(create: (_) => AssetListProvider()),
    ChangeNotifierProvider(create: (_) => SpotPriceProvider()),
    ChangeNotifierProvider(create: (_) => HistoryProvider()),
    ChangeNotifierProvider(create: (_) => FxNotifier(1.0)),
    ChangeNotifierProvider(create: (_) => ProfitDisplayModeNotifier()),
    ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
    ChangeNotifierProxyProvider<AppInitializationProvider, InvestmentProvider>(
      create: (_) => InvestmentProvider(InvestmentRepositoryImpl()),
      update: (context, appInit, previous) {
        return InvestmentProvider(appInit.repository ?? InvestmentRepositoryImpl());
      },
    ),
  ];
}
