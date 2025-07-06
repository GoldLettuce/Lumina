import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'domain/entities/investment.dart';
import 'data/repositories_impl/investment_repository_impl.dart';

import 'ui/providers/chart_value_provider.dart';
import 'ui/providers/asset_list_provider.dart';
import 'ui/providers/settings_provider.dart';
import 'ui/providers/locale_provider.dart';
import 'ui/providers/investment_provider.dart';
import 'ui/providers/currency_provider.dart';

import 'ui/screens/portfolio_screen.dart';
import 'core/point.dart';
import 'data/models/local_history.dart';
import 'data/models/chart_cache.dart';
import 'domain/entities/asset_type.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Registro de adaptadores
  Hive.registerAdapter(InvestmentAdapter());
  Hive.registerAdapter(InvestmentOperationAdapter());
  Hive.registerAdapter(PointAdapter());
  Hive.registerAdapter(LocalHistoryAdapter());
  Hive.registerAdapter(ChartCacheAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(AssetTypeAdapter());

  // ✅ Abre la caja una sola vez y la deja disponible para toda la app
  await Hive.openBox<Investment>(InvestmentRepositoryImpl.boxName);

  final investmentRepository = InvestmentRepositoryImpl();
  await investmentRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetListProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider(investmentRepository)),
        ChangeNotifierProvider(create: (_) => ChartValueProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: const PortfolioApp(),
    ),
  );
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      title: 'Mi Portafolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      home: const PortfolioScreen(),
    );
  }
}
