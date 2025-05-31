import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:lumina/core/point.dart';


class PointListAdapter extends TypeAdapter<List<Point>> {
  @override
  int get typeId => 10;

  @override
  List<Point> read(BinaryReader reader) {
    final compressed = reader.readByteList();
    final decompressed = GZipCodec().decode(compressed);
    final jsonStr = utf8.decode(decompressed);
    final list = (jsonDecode(jsonStr) as List)
        .map((e) => Point.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  void write(BinaryWriter writer, List<Point> obj) {
    final jsonStr = jsonEncode(obj.map((e) => e.toJson()).toList());
    final bytes = utf8.encode(jsonStr);
    final compressed = GZipCodec().encode(Uint8List.fromList(bytes));
    writer.writeByteList(compressed);
  }
}
