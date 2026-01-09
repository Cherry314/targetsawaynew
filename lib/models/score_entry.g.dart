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
      score: fields[2] as int,
      practice: fields[3] as String,
      caliber: fields[4] as String,
      firearmId: fields[5] as String,
      firearm: fields[6] as String?,
      notes: fields[7] as String?,
      comp: fields[8] as bool,
      compId: fields[9] as String?,
      compResult: fields[10] as String?,
      targetFilePath: fields[11] as String?,
      thumbnailFilePath: fields[12] as String?,
      targetCaptured: fields[13] as bool,
      x: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreEntry obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.practice)
      ..writeByte(4)
      ..write(obj.caliber)
      ..writeByte(5)
      ..write(obj.firearmId)
      ..writeByte(6)
      ..write(obj.firearm)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.comp)
      ..writeByte(9)
      ..write(obj.compId)
      ..writeByte(10)
      ..write(obj.compResult)
      ..writeByte(11)
      ..write(obj.targetFilePath)
      ..writeByte(12)
      ..write(obj.thumbnailFilePath)
      ..writeByte(13)
      ..write(obj.targetCaptured)
      ..writeByte(14)
      ..write(obj.x);
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
