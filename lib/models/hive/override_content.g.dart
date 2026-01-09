// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'override_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OverrideContentAdapter extends TypeAdapter<OverrideContent> {
  @override
  final int typeId = 103;

  @override
  OverrideContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OverrideContent(
      targets: (fields[0] as List?)?.cast<Target>(),
      ammunition: (fields[21] as List?)?.cast<Ammunition>(),
      sights: (fields[1] as List?)?.cast<Sight>(),
      positions: (fields[2] as List?)?.cast<Position>(),
      readyPositions: (fields[3] as List?)?.cast<ReadyPosition>(),
      rangeCommands: (fields[4] as List?)?.cast<RangeCommand>(),
      notes: (fields[5] as List?)?.cast<EventNotes>(),
      ties: (fields[6] as List?)?.cast<Tie>(),
      proceduralPenalties: (fields[7] as List?)?.cast<ProceduralPenalty>(),
      classifications: (fields[8] as List?)?.cast<Classification>(),
      targetPositions: (fields[9] as List?)?.cast<TargetPosition>(),
      courseOfFire: fields[10] as CourseOfFire?,
      sighters: (fields[11] as List?)?.cast<Sighters>(),
      practices: (fields[12] as List?)?.cast<Practice>(),
      targetIds: (fields[13] as List?)?.cast<TargetID>(),
      generalNotes: fields[14] as Notes?,
      scoring: fields[15] as Scoring?,
      loading: fields[16] as Loading?,
      reloading: fields[17] as Reloading?,
      equipment: fields[18] as Equipment?,
      rangeEquipment: fields[19] as RangeEquipment?,
      changingPosition: fields[20] as ChangingPosition?,
    );
  }

  @override
  void write(BinaryWriter writer, OverrideContent obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.targets)
      ..writeByte(21)
      ..write(obj.ammunition)
      ..writeByte(1)
      ..write(obj.sights)
      ..writeByte(2)
      ..write(obj.positions)
      ..writeByte(3)
      ..write(obj.readyPositions)
      ..writeByte(4)
      ..write(obj.rangeCommands)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.ties)
      ..writeByte(7)
      ..write(obj.proceduralPenalties)
      ..writeByte(8)
      ..write(obj.classifications)
      ..writeByte(9)
      ..write(obj.targetPositions)
      ..writeByte(10)
      ..write(obj.courseOfFire)
      ..writeByte(11)
      ..write(obj.sighters)
      ..writeByte(12)
      ..write(obj.practices)
      ..writeByte(13)
      ..write(obj.targetIds)
      ..writeByte(14)
      ..write(obj.generalNotes)
      ..writeByte(15)
      ..write(obj.scoring)
      ..writeByte(16)
      ..write(obj.loading)
      ..writeByte(17)
      ..write(obj.reloading)
      ..writeByte(18)
      ..write(obj.equipment)
      ..writeByte(19)
      ..write(obj.rangeEquipment)
      ..writeByte(20)
      ..write(obj.changingPosition);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverrideContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
