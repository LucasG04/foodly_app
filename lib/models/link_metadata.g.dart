// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinkMetadataAdapter extends TypeAdapter<LinkMetadata> {
  @override
  final int typeId = 1;

  @override
  LinkMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinkMetadata(
      url: fields[0] as String?,
      image: fields[1] as String?,
      title: fields[2] as String?,
      description: fields[3] as String?,
      cachedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LinkMetadata obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.image)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
