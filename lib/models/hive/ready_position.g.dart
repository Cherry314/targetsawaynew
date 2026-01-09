// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ready_position.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadyPositionAdapter extends TypeAdapter<ReadyPosition> {
  @override
  final int typeId = 109;

  @override
  ReadyPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadyPosition(
      text: fields[0] as String?,
      title: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadyPosition obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadyPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
