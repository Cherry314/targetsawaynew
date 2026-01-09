// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 100;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      eventNumber: fields[0] as int,
      name: fields[1] as String,
      applicableFirearmIds: (fields[2] as List).cast<int>(),
      baseContent: fields[3] as EventContent,
      overrides: (fields[4] as List).cast<EventOverride>(),
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.eventNumber)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.applicableFirearmIds)
      ..writeByte(3)
      ..write(obj.baseContent)
      ..writeByte(4)
      ..write(obj.overrides);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
