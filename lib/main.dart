import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/providers/locale_provider.dart';
import 'ui/providers/asset_list_provider.dart';
import 'ui/providers/investment_provider.dart';
import 'ui/providers/spot_price_provider.dart';
import 'ui/providers/history_provider.dart';
import 'ui/providers/fx_notifier.dart';
import 'ui/providers/settings_provider.dart';
import 'ui/providers/currency_provider.dart';
import 'ui/screens/portfolio_screen.dart';
import 'core/hive_service.dart';
import 'data/repositories_impl/investment_repository_impl.dart';
import 'package:flutter/rendering.dart';

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
    return MaterialApp(
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
      home: const AppLoader(),
    );
  }
}

/// Widget que maneja la carga inicial y la creación de providers
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Show skeleton screen while loading
          return const PortfolioScreen();
        }
        
        // All Hive boxes are now open, safe to create providers
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AssetListProvider()),
            ChangeNotifierProvider(create: (_) => InvestmentProvider(_createRepo())),
            ChangeNotifierProvider(create: (_) => SpotPriceProvider()),
            ChangeNotifierProvider(create: (_) => HistoryProvider()),
            ChangeNotifierProvider(create: (_) => FxNotifier(1.0)),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: const PortfolioScreen(),
        );
      },
    );
  }

  /// Inicializa la app completa (Hive + repositorio)
  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    print('[ARRANQUE][${startTime.toIso8601String()}] 🚀 Iniciando carga asíncrona');
    
    // Fase 1: Abre todas las cajas Hive
    final hiveStart = DateTime.now();
    await HiveService.openAllBoxes();
    final hiveEnd = DateTime.now();
    print('[ARRANQUE][${hiveEnd.toIso8601String()}] 📦 Hive abierto en ${hiveEnd.difference(hiveStart).inMilliseconds}ms');
    
    // Fase 2: Inicializa el repositorio en un isolate para evitar bloques en UI
    final repoStart = DateTime.now();
    await compute(_initRepoInBackground, null);
    final repoEnd = DateTime.now();
    print('[ARRANQUE][${repoEnd.toIso8601String()}] 🔧 Repositorio inicializado en ${repoEnd.difference(repoStart).inMilliseconds}ms');
    
    final totalTime = DateTime.now().difference(startTime);
    print('[ARRANQUE][${DateTime.now().toIso8601String()}] ✅ Carga completa en ${totalTime.inMilliseconds}ms');
  }

  /// Crea un repositorio (ahora seguro porque las cajas ya están abiertas)
  InvestmentRepositoryImpl _createRepo() {
    return InvestmentRepositoryImpl();
  }

  /// Inicializa el repositorio en un isolate separado
  static Future<void> _initRepoInBackground(void _) async {
    final startTime = DateTime.now();
    print('[ISOLATE][${startTime.toIso8601String()}] 🔧 Iniciando repositorio en isolate');
    
    final repository = InvestmentRepositoryImpl();
    await repository.init(); // Ahora con await ya que init() es async
    
    final endTime = DateTime.now();
    print('[ISOLATE][${endTime.toIso8601String()}] ✅ Repositorio listo en ${endTime.difference(startTime).inMilliseconds}ms');
  }
}
