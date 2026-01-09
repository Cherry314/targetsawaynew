// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_id.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TargetIDAdapter extends TypeAdapter<TargetID> {
  @override
  final int typeId = 126;

  @override
  TargetID read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TargetID(
      title: fields[0] as String?,
      imageLocation: fields[1] as String?,
      zones: (fields[2] as List?)?.cast<Zone>(),
    );
  }

  @override
  void write(BinaryWriter writer, TargetID obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.imageLocation)
      ..writeByte(2)
      ..write(obj.zones);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetIDAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
