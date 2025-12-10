// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreEntryAdapter extends TypeAdapter<ScoreEntry> {
  @override
  final int typeId = 1;

  @override
  ScoreEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      practice: fields[2] as String,
      caliber: fields[3] as String,
      score: fields[4] as int,
      targetCaptured: fields[5] as bool,
      targetFilePath: fields[6] as String?,
      thumbnailFilePath: fields[7] as String?,
      firearmId: fields[8] as String?,
      firearm: fields[9] as String?,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.practice)
      ..writeByte(3)
      ..write(obj.caliber)
      ..writeByte(4)
      ..write(obj.score)
      ..writeByte(5)
      ..write(obj.targetCaptured)
      ..writeByte(6)
      ..write(obj.targetFilePath)
      ..writeByte(7)
      ..write(obj.thumbnailFilePath)
      ..writeByte(8)
      ..write(obj.firearmId)
      ..writeByte(9)
      ..write(obj.firearm)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
