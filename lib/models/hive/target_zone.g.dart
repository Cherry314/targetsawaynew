// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_zone.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TargetZoneAdapter extends TypeAdapter<TargetZone> {
  @override
  final int typeId = 131;

  @override
  TargetZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TargetZone(
      score: fields[0] as String,
      min: fields[1] as double?,
      max: fields[2] as double?,
      rot: fields[3] as String?,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TargetZone obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.score)
      ..writeByte(1)
      ..write(obj.min)
      ..writeByte(2)
      ..write(obj.max)
      ..writeByte(3)
      ..write(obj.rot)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
