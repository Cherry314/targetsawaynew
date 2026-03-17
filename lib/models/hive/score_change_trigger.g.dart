// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_change_trigger.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreChangeTriggerAdapter extends TypeAdapter<ScoreChangeTrigger> {
  @override
  final int typeId = 135;

  @override
  ScoreChangeTrigger read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreChangeTrigger(
      mode: fields[0] as int,
      checkpoints: (fields[1] as List?)?.cast<ScoreChangeCheckpoint>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, ScoreChangeTrigger obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.mode)
      ..writeByte(1)
      ..write(obj.checkpoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreChangeTriggerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScoreChangeCheckpointAdapter extends TypeAdapter<ScoreChangeCheckpoint> {
  @override
  final int typeId = 136;

  @override
  ScoreChangeCheckpoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreChangeCheckpoint(
      practiceNumber: fields[0] as int,
      stageNumber: fields[1] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreChangeCheckpoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.practiceNumber)
      ..writeByte(1)
      ..write(obj.stageNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreChangeCheckpointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
