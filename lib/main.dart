import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/* ───────── CORE ───────── */
import 'core/theme.dart';
import 'core/history_sync_scheduler.dart';

/* ───────── MODELOS Hive ───────── */
import 'data/models/investment_model.dart';
import 'data/models/investment.dart';
import 'data/models/asset_history_model.dart';

/* ───────── DATA SOURCES ───────── */
import 'data/datasources/coingecko_price_service.dart';
import 'data/datasources/coingecko_history_service.dart';

/* ───────── REPOSITORIES IMPL ───────── */
import 'data/repositories_impl/investment_repository_impl.dart';
import 'data/repositories_impl/history_repository_impl.dart';
import 'data/repositories_impl/price_repository_impl.dart';

/* ───────── REPOSITORIES DOMAIN ───────── */
import 'domain/repositories/price_repository.dart';
import 'domain/repositories/history_repository.dart';

/* ───────── UI PROVIDERS / SCREENS ───────── */
import 'ui/providers/chart_value_provider.dart';
import 'ui/screens/portfolio_screen.dart';
import 'ui/screens/debug_history_screen.dart';

/* ───────── I18N ───────── */
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* ── Inicializar Hive ───────────────────────────────────────── */
  await Hive.initFlutter();

  Hive.registerAdapter(InvestmentAdapter());
  Hive.registerAdapter(InvestmentOperationAdapter());
  Hive.registerAdapter(AssetHistoryModelAdapter());
  Hive.registerAdapter(HistoryPointModelAdapter());

  await Hive.openBox<AssetHistoryModel>('asset_histories');
  await Hive.openBox('history_meta');

  /* ── Repositorios ───────────────────────────────────────────── */
  final investmentRepository = InvestmentRepositoryImpl();
  await investmentRepository.init();

  final coingeckoPriceService = CoinGeckoPriceService();
  final coingeckoHistoryService = CoinGeckoHistoryService();

  final priceRepository =
  PriceRepositoryImpl(coingeckoPriceService, coingeckoHistoryService);

  final historyRepository = HistoryRepositoryImpl(coingeckoHistoryService);

  /* ── Compactación automática de históricos ─────────────────── */
  final scheduler = HistorySyncScheduler(historyRepository);
  await scheduler.runDailyCompaction();

  /* ── Ejecutar la app ────────────────────────────────────────── */
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InvestmentModel(investmentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ChartValueProvider(),
        ),
        Provider<PriceRepository>.value(value: priceRepository),
        Provider<HistoryRepository>.value(value: historyRepository),
      ],
      child: const PortfolioApp(),
    ),
  );
}

/* ─────────────────────────────────────────────────────────────── */

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Portafolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
      home: const PortfolioScreenWithDebugAccess(),
    );
  }
}

/* ─────────────────────────────────────────────────────────────── */

class PortfolioScreenWithDebugAccess extends StatelessWidget {
  const PortfolioScreenWithDebugAccess({super.key});

  @override
  Widget build(BuildContext context) {
    // Pulsación larga → pantalla oculta de depuración de históricos
    return GestureDetector(
      onLongPress: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DebugHistoryScreen()),
        );
      },
      child: const PortfolioScreen(),
    );
  }
}
