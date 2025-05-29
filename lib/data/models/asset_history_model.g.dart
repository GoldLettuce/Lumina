// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetHistoryModelAdapter extends TypeAdapter<AssetHistoryModel> {
  @override
  final int typeId = 4;

  @override
  AssetHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetHistoryModel(
      symbol: fields[0] as String,
      timeRanges: (fields[1] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<HistoryPointModel>())),
    );
  }

  @override
  void write(BinaryWriter writer, AssetHistoryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.timeRanges);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoryPointModelAdapter extends TypeAdapter<HistoryPointModel> {
  @override
  final int typeId = 5;

  @override
  HistoryPointModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryPointModel(
      timestamp: fields[0] as int,
      value: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryPointModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryPointModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
