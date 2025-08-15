// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PointAdapter extends TypeAdapter<Point> {
  @override
  final int typeId = 2;

  @override
  Point read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Point(
      time: fields[0] as DateTime,
      value: fields[1] as double,
      gainUsd: fields[2] as double,
      gainPct: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Point obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.gainUsd)
      ..writeByte(3)
      ..write(obj.gainPct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
