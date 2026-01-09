// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_notes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventNotesAdapter extends TypeAdapter<EventNotes> {
  @override
  final int typeId = 116;

  @override
  EventNotes read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventNotes(
      text: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EventNotes obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventNotesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
