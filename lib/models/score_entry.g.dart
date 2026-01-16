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
      scoreX: fields[15] as int?,
      score10: fields[16] as int?,
      score9: fields[17] as int?,
      score8: fields[18] as int?,
      score7: fields[19] as int?,
      score6: fields[20] as int?,
      score5: fields[21] as int?,
      score4: fields[22] as int?,
      score3: fields[23] as int?,
      score2: fields[24] as int?,
      score1: fields[25] as int?,
      score0: fields[26] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreEntry obj) {
    writer
      ..writeByte(27)
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
      ..write(obj.x)
      ..writeByte(15)
      ..write(obj.scoreX)
      ..writeByte(16)
      ..write(obj.score10)
      ..writeByte(17)
      ..write(obj.score9)
      ..writeByte(18)
      ..write(obj.score8)
      ..writeByte(19)
      ..write(obj.score7)
      ..writeByte(20)
      ..write(obj.score6)
      ..writeByte(21)
      ..write(obj.score5)
      ..writeByte(22)
      ..write(obj.score4)
      ..writeByte(23)
      ..write(obj.score3)
      ..writeByte(24)
      ..write(obj.score2)
      ..writeByte(25)
      ..write(obj.score1)
      ..writeByte(26)
      ..write(obj.score0);
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
