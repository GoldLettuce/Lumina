// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_price.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpotPriceAdapter extends TypeAdapter<SpotPrice> {
  @override
  final int typeId = 10;

  @override
  SpotPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpotPrice(
      symbol: fields[0] as String,
      price: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SpotPrice obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
