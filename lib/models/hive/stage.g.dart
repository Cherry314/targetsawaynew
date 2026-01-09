// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StageAdapter extends TypeAdapter<Stage> {
  @override
  final int typeId = 128;

  @override
  Stage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stage(
      stageNumber: fields[0] as int,
      distance: fields[1] as int?,
      distanceText: fields[2] as String?,
      rounds: fields[3] as int?,
      roundsText: fields[4] as String?,
      time: fields[5] as double?,
      timeText: fields[6] as String?,
      notesHeader: fields[7] as String?,
      notes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Stage obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.stageNumber)
      ..writeByte(1)
      ..write(obj.distance)
      ..writeByte(2)
      ..write(obj.distanceText)
      ..writeByte(3)
      ..write(obj.rounds)
      ..writeByte(4)
      ..write(obj.roundsText)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.timeText)
      ..writeByte(7)
      ..write(obj.notesHeader)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
