// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChartCacheAdapter extends TypeAdapter<ChartCache> {
  @override
  final int typeId = 5;

  @override
  ChartCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChartCache(
      history: (fields[0] as List).cast<Point>(),
      spotPrices: (fields[1] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChartCache obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.history)
      ..writeByte(1)
      ..write(obj.spotPrices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
