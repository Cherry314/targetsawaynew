// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_stage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PracticeStageAdapter extends TypeAdapter<PracticeStage> {
  @override
  final int typeId = 129;

  @override
  PracticeStage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PracticeStage(
      distance: fields[0] as int?,
      rounds: fields[1] as int?,
      time: fields[2] as int?,
      notesHeader: fields[3] as String,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PracticeStage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.distance)
      ..writeByte(1)
      ..write(obj.rounds)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.notesHeader)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeStageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
