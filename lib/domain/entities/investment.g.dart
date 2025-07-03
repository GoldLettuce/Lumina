// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentAdapter extends TypeAdapter<Investment> {
  @override
  final int typeId = 0;

  @override
  Investment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Investment(
      symbol: fields[0] as String,
      name: fields[1] as String,
      type: fields[3] as AssetType,
      coingeckoId: fields[4] as String,
      vsCurrency: fields[5] as String,
      operations: (fields[2] as List?)?.cast<InvestmentOperation>(),
    );
  }

  @override
  void write(BinaryWriter writer, Investment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.operations)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.coingeckoId)
      ..writeByte(5)
      ..write(obj.vsCurrency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvestmentOperationAdapter extends TypeAdapter<InvestmentOperation> {
  @override
  final int typeId = 1;

  @override
  InvestmentOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentOperation(
      quantity: fields[0] as double,
      price: fields[1] as double,
      date: fields[2] as DateTime,
      type: fields[3] as OperationType,
      id: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentOperation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.quantity)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
