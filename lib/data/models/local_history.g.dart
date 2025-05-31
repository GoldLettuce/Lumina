// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalHistoryAdapter extends TypeAdapter<LocalHistory> {
  @override
  final int typeId = 3;

  @override
  LocalHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalHistory(
      from: fields[0] as DateTime,
      to: fields[1] as DateTime,
      points: (fields[2] as List).cast<Point>(),
      needsRebuild: fields[3] == null ? false : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.from)
      ..writeByte(1)
      ..write(obj.to)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.needsRebuild);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
