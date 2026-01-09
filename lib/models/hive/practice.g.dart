// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PracticeAdapter extends TypeAdapter<Practice> {
  @override
  final int typeId = 127;

  @override
  Practice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Practice(
      practiceNumber: fields[0] as int,
      stages: (fields[1] as List).cast<Stage>(),
      notesHeader: fields[2] as String?,
      notes: fields[3] as String?,
      practiceName: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Practice obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.practiceNumber)
      ..writeByte(1)
      ..write(obj.stages)
      ..writeByte(2)
      ..write(obj.notesHeader)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.practiceName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
