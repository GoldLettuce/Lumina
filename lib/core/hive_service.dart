import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/entities/asset_type.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/models/chart_cache.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';

/// Servicio centralizado para gestionar todas las cajas de Hive
///
/// Este servicio abre todas las cajas necesarias una sola vez al inicio
/// de la aplicación, evitando múltiples aperturas que pueden causar
/// bloqueos de UI y mejorar el rendimiento general.
class HiveService {
  // Cajas principales
  static LazyBox<Investment>? _investmentsBox;
  static Box<ChartCache>? _chartCacheBox;
  static Box<LocalHistory>? _historyBox;

  // Cajas de configuración y servicios
  static Box? _settingsBox;
  static Box? _fxRatesBox;
  static Box? _metaBox;

  // Getters públicos para acceder a las cajas
  static LazyBox<Investment> get investments => _investmentsBox!;
  static Box<ChartCache> get chartCache => _chartCacheBox!;
  static Box<LocalHistory> get history => _historyBox!;
  static Box get settings => _settingsBox!;
  static Box get fxRates => _fxRatesBox!;
  static Box get metaBox => _metaBox!;

  static bool _adaptersRegistered = false;

  // Guarda la Future de la apertura para reutilizarla
  static Future<void>? _openFuture;
  static bool _isInitialized = false;

  /// Inicializa Hive Flutter y registra adaptadores (método ligero)
  static Future<void> initFlutterLight() async {
    await Hive.initFlutter();
    if (!_adaptersRegistered) {
      registerAdapters();
      _adaptersRegistered = true;
    }
  }

  /// Abre todas las cajas necesarias (método pesado)
  static Future<void> openAllBoxes() {
    _openFuture ??= _openAllBoxesInternal();
    return _openFuture!;
  }

  /// Método interno que contiene la lógica de apertura de cajas
  static Future<void> _openAllBoxesInternal() async {
    final startTime = DateTime.now();
    print(
      '[HIVE][${startTime.toIso8601String()}] 📦 Iniciando apertura de cajas',
    );

    // Fase 1: Abre solo la caja de configuración (mínima y rápida)
    final settingsStart = DateTime.now();
    _settingsBox = await Hive.openBox('settingsBox');
    await Future.delayed(Duration.zero);
    final settingsEnd = DateTime.now();
    print(
      '[HIVE][${settingsEnd.toIso8601String()}] ⚙️ Settings abierta en ${settingsEnd.difference(settingsStart).inMilliseconds}ms',
    );

    // Fase 2: Abre el resto de cajas y espera a que terminen
    print(
      '[HIVE][${DateTime.now().toIso8601String()}] 🔄 Abriendo cajas pesadas (esperando a que terminen)',
    );
    
    final heavyStart = DateTime.now();
    await _openInvestmentsBox();
    await _openChartCacheBox();
    await _openHistoryBox();
    await _openFxRatesBox();
    await _openMetaBox();
    final heavyEnd = DateTime.now();
    print(
      '[HIVE][${heavyEnd.toIso8601String()}] ✅ Cajas pesadas abiertas en ${heavyEnd.difference(heavyStart).inMilliseconds}ms',
    );
    _isInitialized = true;
  }

  /// Inicializa Hive y abre todas las cajas necesarias
  ///
  /// Este método debe llamarse una sola vez al inicio de la aplicación,
  /// antes de usar cualquier funcionalidad que requiera acceso a Hive.
  static Future<void> init() async {
    print(
      '[ARRANQUE][${DateTime.now().toIso8601String()}] 📦 HiveService.init() START',
    );
    await initFlutterLight();
    await openAllBoxes();
    _isInitialized = true;
    print(
      '[ARRANQUE][${DateTime.now().toIso8601String()}] �� HiveService.init() END',
    );
  }

  /// Registra todos los adapters de Hive necesarios
  static void registerAdapters() {
    Hive.registerAdapter(InvestmentAdapter());
    Hive.registerAdapter(InvestmentOperationAdapter());
    Hive.registerAdapter(OperationTypeAdapter());
    Hive.registerAdapter(AssetTypeAdapter());
    Hive.registerAdapter(PointAdapter());
    Hive.registerAdapter(LocalHistoryAdapter());
    Hive.registerAdapter(ChartCacheAdapter());
  }

  /// Abre la caja de inversiones como LazyBox
  static Future<void> _openInvestmentsBox() async {
    _investmentsBox = await Hive.openLazyBox<Investment>(
      InvestmentRepositoryImpl.boxName,
    );
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de caché de gráficos
  static Future<void> _openChartCacheBox() async {
    _chartCacheBox = await Hive.openBox<ChartCache>('chart_cache');
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de historial local
  static Future<void> _openHistoryBox() async {
    _historyBox = await Hive.openBox<LocalHistory>('history');
    await Future.delayed(Duration.zero);
  }



  /// Abre la caja de tasas de cambio
  static Future<void> _openFxRatesBox() async {
    _fxRatesBox = await Hive.openBox('fxRatesBox');
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de metadatos
  static Future<void> _openMetaBox() async {
    _metaBox = await Hive.openBox('metaBox');
    await Future.delayed(Duration.zero);
  }

  /// Verifica si todas las cajas están inicializadas
  static bool get isInitialized {
    return _isInitialized;
  }

  /// Cierra todas las cajas (útil para testing o cleanup)
  static Future<void> closeAll() async {
    await Future.wait([
      _investmentsBox?.close() ?? Future.value(),
      _chartCacheBox?.close() ?? Future.value(),
      _historyBox?.close() ?? Future.value(),
      _settingsBox?.close() ?? Future.value(),
      _fxRatesBox?.close() ?? Future.value(),
      _metaBox?.close() ?? Future.value(),
    ]);

    _investmentsBox = null;
    _chartCacheBox = null;
    _historyBox = null;
    _settingsBox = null;
    _fxRatesBox = null;
    _metaBox = null;
    _openFuture = null;
    _isInitialized = false;
  }

  /// Reabre la caja de inversiones (útil después de reset)
  static Future<void> reopenInvestmentsBox() async {
    _investmentsBox = await Hive.openLazyBox<Investment>(
      InvestmentRepositoryImpl.boxName,
    );
    await Future.delayed(Duration.zero);
  }

  /// Reabre la caja de caché de gráficos (útil después de reset)
  static Future<void> reopenChartCacheBox() async {
    _chartCacheBox = await Hive.openBox<ChartCache>('chart_cache');
    await Future.delayed(Duration.zero);
  }
}
