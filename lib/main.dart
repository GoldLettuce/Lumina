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
import 'ui/providers/app_initialization_provider.dart';

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
      home: ChangeNotifierProvider(
        create: (_) => AppInitializationProvider()..initialize(),
        child: const PortfolioGate(),
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
    // Cuando todo está listo, inyecta los providers reales
    final data = appInit.preloadedData;
    final repo = appInit.repository;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetListProvider(/* data['assets'] */)),
        ChangeNotifierProvider(create: (_) => InvestmentProvider(repo)),
        ChangeNotifierProvider(create: (_) => SpotPriceProvider(/* data['spotPrices'] */)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(/* data['history'] */)),
        ChangeNotifierProvider(create: (_) => FxNotifier(data['fx'] ?? 1.0)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(/* data['settings'] */)),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider(/* data['currency'] */)),
      ],
      child: const PortfolioScreen(),
    );
  }
}

/// Widget que maneja la carga inicial y la creación de providers
/// Retrasa la carga pesada hasta después del primer frame para evitar skipped frames
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _started = false;
  late Future<void> _initializationFuture;
  late InvestmentRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    print('[ARRANQUE][${DateTime.now().toIso8601String()}] 🎬 AppLoader.initState() - Esperando primer frame');
    
    // Retrasar la carga pesada hasta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[ARRANQUE][${DateTime.now().toIso8601String()}] 🎬 Primer frame pintado - Iniciando carga pesada');
      setState(() {
        _started = true;
        _initializationFuture = _initializeApp();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar skeleton inmediatamente mientras esperamos el primer frame
    if (!_started) {
      print('[ARRANQUE][${DateTime.now().toIso8601String()}] 🎬 Mostrando skeleton inicial');
      return const PortfolioScreen(); // PortfolioScreen maneja el skeleton internamente
    }

    // Una vez que el primer frame está pintado, iniciar la carga pesada
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Continuar mostrando skeleton mientras se carga
          print('[ARRANQUE][${DateTime.now().toIso8601String()}] 🔄 Cargando datos...');
          return const PortfolioScreen();
        }
        
        // Todos los datos están listos, crear providers y mostrar app completa
        print('[ARRANQUE][${DateTime.now().toIso8601String()}] ✅ Datos listos - Creando providers');
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
    _repository = await compute(_initRepoInBackground, null);
    final repoEnd = DateTime.now();
    print('[ARRANQUE][${repoEnd.toIso8601String()}] 🔧 Repositorio inicializado en ${repoEnd.difference(repoStart).inMilliseconds}ms');
    
    final totalTime = DateTime.now().difference(startTime);
    print('[ARRANQUE][${DateTime.now().toIso8601String()}] ✅ Carga completa en ${totalTime.inMilliseconds}ms');
  }

  /// Crea un repositorio (reutiliza el ya inicializado en el isolate)
  InvestmentRepositoryImpl _createRepo() {
    return _repository; // Reutiliza el repositorio ya inicializado
  }

  /// Inicializa el repositorio en un isolate separado
  static Future<InvestmentRepositoryImpl> _initRepoInBackground(void _) async {
    final startTime = DateTime.now();
    print('[ISOLATE][${startTime.toIso8601String()}] 🔧 Iniciando repositorio en isolate');
    
    final repository = InvestmentRepositoryImpl();
    await repository.init(); // Ahora con await ya que init() es async
    
    final endTime = DateTime.now();
    print('[ISOLATE][${endTime.toIso8601String()}] ✅ Repositorio listo en ${endTime.difference(startTime).inMilliseconds}ms');
    
    return repository; // Retorna el repositorio inicializado
  }
}
