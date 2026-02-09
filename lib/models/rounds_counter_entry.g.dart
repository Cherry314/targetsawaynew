// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rounds_counter_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoundsCounterEntryAdapter extends TypeAdapter<RoundsCounterEntry> {
  @override
  final int typeId = 5;

  @override
  RoundsCounterEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoundsCounterEntry(
      date: fields[0] as DateTime,
      rounds: fields[1] as int,
      reason: fields[2] as String,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RoundsCounterEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.rounds)
      ..writeByte(2)
      ..write(obj.reason)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundsCounterEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
