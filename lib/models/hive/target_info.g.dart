// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TargetInfoAdapter extends TypeAdapter<TargetInfo> {
  @override
  final int typeId = 132;

  @override
  TargetInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TargetInfo(
      targetName: fields[0] as String,
      imageLocation: fields[1] as String?,
      notes: fields[2] as String?,
      zones: (fields[3] as List).cast<TargetZone>(),
    );
  }

  @override
  void write(BinaryWriter writer, TargetInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.targetName)
      ..writeByte(1)
      ..write(obj.imageLocation)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.zones);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
