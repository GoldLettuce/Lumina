// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetTypeAdapter extends TypeAdapter<AssetType> {
  @override
  final int typeId = 7;

  @override
  AssetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetType.crypto;
      case 1:
        return AssetType.stock;
      case 2:
        return AssetType.etf;
      case 3:
        return AssetType.commodity;
      default:
        return AssetType.crypto;
    }
  }

  @override
  void write(BinaryWriter writer, AssetType obj) {
    switch (obj) {
      case AssetType.crypto:
        writer.writeByte(0);
        break;
      case AssetType.stock:
        writer.writeByte(1);
        break;
      case AssetType.etf:
        writer.writeByte(2);
        break;
      case AssetType.commodity:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
