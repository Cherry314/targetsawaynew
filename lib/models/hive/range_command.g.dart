// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'range_command.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RangeCommandAdapter extends TypeAdapter<RangeCommand> {
  @override
  final int typeId = 110;

  @override
  RangeCommand read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RangeCommand(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RangeCommand obj) {
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
      other is RangeCommandAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
