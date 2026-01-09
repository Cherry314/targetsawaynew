// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magazine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MagazineAdapter extends TypeAdapter<Magazine> {
  @override
  final int typeId = 121;

  @override
  Magazine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Magazine(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Magazine obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MagazineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
