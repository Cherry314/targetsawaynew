// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changing_position.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChangingPositionAdapter extends TypeAdapter<ChangingPosition> {
  @override
  final int typeId = 125;

  @override
  ChangingPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChangingPosition(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChangingPosition obj) {
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
      other is ChangingPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
