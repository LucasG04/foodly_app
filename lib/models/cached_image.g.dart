// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedImageAdapter extends TypeAdapter<CachedImage> {
  @override
  final int typeId = 2;

  @override
  CachedImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedImage(
      imageBytes: fields[0] as Uint8List,
      lastAccessed: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedImage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.imageBytes)
      ..writeByte(1)
      ..write(obj.lastAccessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
