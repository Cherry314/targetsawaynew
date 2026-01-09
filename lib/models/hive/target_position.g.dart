// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_position.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TargetPositionAdapter extends TypeAdapter<TargetPosition> {
  @override
  final int typeId = 114;

  @override
  TargetPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TargetPosition(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TargetPosition obj) {
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
      other is TargetPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
