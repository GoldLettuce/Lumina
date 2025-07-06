import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/entities/asset_type.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/models/chart_cache.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';

Future<InvestmentRepositoryImpl> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(InvestmentAdapter());
  Hive.registerAdapter(InvestmentOperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(AssetTypeAdapter());
  Hive.registerAdapter(PointAdapter());
  Hive.registerAdapter(LocalHistoryAdapter());
  Hive.registerAdapter(ChartCacheAdapter());

  await Hive.openBox<Investment>(InvestmentRepositoryImpl.boxName);

  final repository = InvestmentRepositoryImpl();
  await repository.init();

  return repository;
}
