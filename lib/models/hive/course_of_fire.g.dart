// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_of_fire.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseOfFireAdapter extends TypeAdapter<CourseOfFire> {
  @override
  final int typeId = 115;

  @override
  CourseOfFire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseOfFire(
      distance: fields[0] as int?,
      distanceNotes: fields[1] as String?,
      totalTime: fields[2] as int?,
      timeNotes: fields[3] as String?,
      totalRounds: fields[4] as int?,
      roundsNotes: fields[5] as String?,
      maxScore: fields[6] as int?,
      maxScoreNotes: fields[7] as String?,
      generalNotes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CourseOfFire obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.distance)
      ..writeByte(1)
      ..write(obj.distanceNotes)
      ..writeByte(2)
      ..write(obj.totalTime)
      ..writeByte(3)
      ..write(obj.timeNotes)
      ..writeByte(4)
      ..write(obj.totalRounds)
      ..writeByte(5)
      ..write(obj.roundsNotes)
      ..writeByte(6)
      ..write(obj.maxScore)
      ..writeByte(7)
      ..write(obj.maxScoreNotes)
      ..writeByte(8)
      ..write(obj.generalNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseOfFireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
