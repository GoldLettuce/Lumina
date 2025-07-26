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
    ProxyProvider<AppInitializationProvider, InvestmentProvider>(
      update: (context, appInit, _) {
        if (appInit.isAppReady && appInit.repository != null) {
          return InvestmentProvider(appInit.repository);
        }
        return InvestmentProvider(InvestmentRepositoryImpl());
      },
    ),
  ];
}
