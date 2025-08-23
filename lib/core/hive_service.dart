import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:lumina/core/hive_key_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/entities/asset_type.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/models/chart_cache.dart';
import 'package:lumina/data/models/spot_price.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/core/theme.dart';

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
    // Crear cipher AES-256 antes de abrir las cajas
    final key = await HiveKeyService.getOrCreateKey();
    final cipher = HiveAesCipher(key);

    // Fase 1: Abre solo la caja de configuración (mínima y rápida)
    _settingsBox = await _openEncryptedBoxOrReset('settingsBox', cipher);
    await Future.delayed(Duration.zero);

    // Fase 2: Abre el resto de cajas y espera a que terminen
    await _openInvestmentsBox(cipher);
    await _openChartCacheBox(cipher);
    await _openHistoryBox(cipher);
    await _openFxRatesBox(cipher);
    await _openMetaBox(cipher);

    _isInitialized = true;
  }

  /// Inicializa Hive y abre todas las cajas necesarias
  ///
  /// Este método debe llamarse una sola vez al inicio de la aplicación,
  /// antes de usar cualquier funcionalidad que requiera acceso a Hive.
  static Future<void> init() async {
    await initFlutterLight();
    await openAllBoxes();
    _isInitialized = true;
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
    Hive.registerAdapter(SpotPriceAdapter());
    Hive.registerAdapter(AppThemeModeAdapter());
  }

  /// Helper para abrir cajas cifradas con reset-on-failure policy
  static Future<Box<T>> _openEncryptedBoxOrReset<T>(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }

  /// Helper para abrir LazyBox cifradas con reset-on-failure policy
  static Future<LazyBox<T>> _openEncryptedLazyBoxOrReset<T>(
    String name,
    HiveAesCipher cipher,
  ) async {
    try {
      return await Hive.openLazyBox<T>(name, encryptionCipher: cipher);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return await Hive.openLazyBox<T>(name, encryptionCipher: cipher);
    }
  }

  /// Abre la caja de inversiones como LazyBox
  static Future<void> _openInvestmentsBox(HiveAesCipher cipher) async {
    _investmentsBox = await _openEncryptedLazyBoxOrReset<Investment>(
      InvestmentRepositoryImpl.boxName,
      cipher,
    );
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de caché de gráficos
  static Future<void> _openChartCacheBox(HiveAesCipher cipher) async {
    _chartCacheBox = await _openEncryptedBoxOrReset<ChartCache>(
      'chart_cache',
      cipher,
    );
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de historial local
  static Future<void> _openHistoryBox(HiveAesCipher cipher) async {
    _historyBox = await _openEncryptedBoxOrReset<LocalHistory>(
      'history',
      cipher,
    );
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de tasas de cambio
  static Future<void> _openFxRatesBox(HiveAesCipher cipher) async {
    _fxRatesBox = await _openEncryptedBoxOrReset('fxRatesBox', cipher);
    await Future.delayed(Duration.zero);
  }

  /// Abre la caja de metadatos
  static Future<void> _openMetaBox(HiveAesCipher cipher) async {
    _metaBox = await _openEncryptedBoxOrReset('metaBox', cipher);
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
  static Future<void> reopenInvestmentsBox(HiveAesCipher cipher) async {
    _investmentsBox = await _openEncryptedLazyBoxOrReset<Investment>(
      InvestmentRepositoryImpl.boxName,
      cipher,
    );
    await Future.delayed(Duration.zero);
  }

  /// Reabre la caja de caché de gráficos (útil después de reset)
  static Future<void> reopenChartCacheBox(HiveAesCipher cipher) async {
    _chartCacheBox = await _openEncryptedBoxOrReset<ChartCache>(
      'chart_cache',
      cipher,
    );
    await Future.delayed(Duration.zero);
  }
}
