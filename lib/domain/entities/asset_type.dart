// lib/domain/entities/asset_type.dart

import 'package:hive/hive.dart';

part 'asset_type.g.dart';

@HiveType(typeId: 7)
enum AssetType {
  @HiveField(0)
  crypto,

  @HiveField(1)
  stock,

  @HiveField(2)
  etf,

  @HiveField(3)
  commodity,
}