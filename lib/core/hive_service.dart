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

  // Getters públicos para acceder a las cajas
  static LazyBox<Investment> get investments => _investmentsBox!;
  static Box<ChartCache> get chartCache => _chartCacheBox!;
  static Box<LocalHistory> get history => _historyBox!;
  static Box get settings => _settingsBox!;
  static Box get fxRates => _fxRatesBox!;

  /// Inicializa solo Hive Flutter y registra los adapters (debe llamarse en el main isolate)
  static Future<void> initFlutterOnly() async {
    await Hive.initFlutter();
    _registerAdapters();
  }

  /// Abre todas las cajas necesarias (ahora espera a que todas estén listas antes de completar)
  /// Fase 1: Caja mínima necesaria para UI
  /// Fase 2: Cajas grandes (espera a que terminen)
  static Future<void> openAllBoxes() async {
    final startTime = DateTime.now();
    print('[HIVE][${startTime.toIso8601String()}] 📦 Iniciando apertura de cajas');
    
    // Fase 1: Abre solo la caja de configuración (mínima y rápida)
    final settingsStart = DateTime.now();
    await _openSettingsBox();
    final settingsEnd = DateTime.now();
    print('[HIVE][${settingsEnd.toIso8601String()}] ⚙️ Settings abierta en ${settingsEnd.difference(settingsStart).inMilliseconds}ms');
    
    // Fase 2: Abre el resto de cajas y espera a que terminen
    print('[HIVE][${DateTime.now().toIso8601String()}] 🔄 Abriendo cajas pesadas (esperando a que terminen)');
    await _openHeavyBoxes();
  }

  /// Abre las cajas pesadas en background
  static Future<void> _openHeavyBoxes() async {
    final startTime = DateTime.now();
    print('[HIVE][${startTime.toIso8601String()}] 🔄 Iniciando apertura de cajas pesadas');
    
    await Future.wait([
      _openInvestmentsBox(),
      _openChartCacheBox(),
      _openHistoryBox(),
      _openFxRatesBox(),
    ]);
    
    final endTime = DateTime.now();
    print('[HIVE][${endTime.toIso8601String()}] ✅ Cajas pesadas abiertas en ${endTime.difference(startTime).inMilliseconds}ms');
  }

  /// Inicializa Hive y abre todas las cajas necesarias
  /// 
  /// Este método debe llamarse una sola vez al inicio de la aplicación,
  /// antes de usar cualquier funcionalidad que requiera acceso a Hive.
  static Future<void> init() async {
    print('[ARRANQUE][${DateTime.now().toIso8601String()}] 📦 HiveService.init() START');
    await initFlutterOnly();
    await openAllBoxes();
    print('[ARRANQUE][${DateTime.now().toIso8601String()}] 📦 HiveService.init() END');
  }

  /// Registra todos los adapters de Hive necesarios
  static void _registerAdapters() {
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
    _investmentsBox = await Hive.openLazyBox<Investment>(InvestmentRepositoryImpl.boxName);
  }

  /// Abre la caja de caché de gráficos
  static Future<void> _openChartCacheBox() async {
    _chartCacheBox = await Hive.openBox<ChartCache>('chart_cache');
  }

  /// Abre la caja de historial local
  static Future<void> _openHistoryBox() async {
    _historyBox = await Hive.openBox<LocalHistory>('history');
  }

  /// Abre la caja de configuración
  static Future<void> _openSettingsBox() async {
    _settingsBox = await Hive.openBox('settingsBox');
  }

  /// Abre la caja de tasas de cambio
  static Future<void> _openFxRatesBox() async {
    _fxRatesBox = await Hive.openBox('fxRatesBox');
  }

  /// Verifica si todas las cajas están inicializadas
  static bool get isInitialized {
    return _investmentsBox != null &&
           _chartCacheBox != null &&
           _historyBox != null &&
           _settingsBox != null &&
           _fxRatesBox != null;
  }

  /// Cierra todas las cajas (útil para testing o cleanup)
  static Future<void> closeAll() async {
    await Future.wait([
      _investmentsBox?.close() ?? Future.value(),
      _chartCacheBox?.close() ?? Future.value(),
      _historyBox?.close() ?? Future.value(),
      _settingsBox?.close() ?? Future.value(),
      _fxRatesBox?.close() ?? Future.value(),
    ]);

    _investmentsBox = null;
    _chartCacheBox = null;
    _historyBox = null;
    _settingsBox = null;
    _fxRatesBox = null;
  }

  /// Reabre la caja de inversiones (útil después de reset)
  static Future<void> reopenInvestmentsBox() async {
    _investmentsBox = await Hive.openLazyBox<Investment>(InvestmentRepositoryImpl.boxName);
  }

  /// Reabre la caja de caché de gráficos (útil después de reset)
  static Future<void> reopenChartCacheBox() async {
    _chartCacheBox = await Hive.openBox<ChartCache>('chart_cache');
  }
} 