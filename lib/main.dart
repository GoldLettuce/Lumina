import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:lumina/ui/providers/locale_provider.dart';
import 'package:lumina/ui/providers/asset_list_provider.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/settings_provider.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import 'package:lumina/ui/screens/portfolio_screen.dart';
import 'package:lumina/core/hive_service.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:flutter/rendering.dart';
import 'package:lumina/ui/providers/app_initialization_provider.dart';

Future<void> main() async {
  debugPrintRebuildDirtyWidgets = true;
  print('[ARRANQUE][${DateTime.now().toIso8601String()}] main() START');
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initFlutterOnly(); // Ahora con await para asegurar inicialización completa
  print('[ARRANQUE][${DateTime.now().toIso8601String()}] Antes de runApp()');
  debugProfileBuildsEnabled = true;
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInitializationProvider()),
        // Providers que estarán disponibles en toda la aplicación
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: MaterialApp(
        title: 'Lumina',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: const PortfolioGate(),
      ),
    );
  }
}

class PortfolioGate extends StatelessWidget {
  const PortfolioGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appInit = context.watch<AppInitializationProvider>();
    if (!appInit.isAppReady) {
      // 🔄 Carga diferida tras primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!appInit.isAppReady) {
          appInit.initialize();
        }
      });
      return SkeletonView(); // Usa tu widget shimmer/skeleton
    }
    // Cuando todo está listo, inyecta los providers específicos del portafolio
    final data = appInit.preloadedData;
    final repo = appInit.repository;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetListProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider(repo)),
        ChangeNotifierProvider(create: (_) => SpotPriceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => FxNotifier(data['fx'] ?? 1.0)),
      ],
      child: const PortfolioScreen(),
    );
  }
}

class SkeletonView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando...',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
