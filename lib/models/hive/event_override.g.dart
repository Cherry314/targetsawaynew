// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_override.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventOverrideAdapter extends TypeAdapter<EventOverride> {
  @override
  final int typeId = 102;

  @override
  EventOverride read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventOverride(
      firearmIds: (fields[0] as List).cast<int>(),
      changes: fields[1] as OverrideContent,
    );
  }

  @override
  void write(BinaryWriter writer, EventOverride obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.firearmIds)
      ..writeByte(1)
      ..write(obj.changes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventOverrideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
