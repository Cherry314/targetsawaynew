// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TargetAdapter extends TypeAdapter<Target> {
  @override
  final int typeId = 105;

  @override
  Target read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Target(
      title: fields[0] as String?,
      text: fields[1] as String?,
      link: fields[2] as String?,
      qtyNeeded: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Target obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.link)
      ..writeByte(3)
      ..write(obj.qtyNeeded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
