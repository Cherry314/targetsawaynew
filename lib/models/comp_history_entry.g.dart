// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comp_history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompHistoryEntryAdapter extends TypeAdapter<CompHistoryEntry> {
  @override
  final int typeId = 134;

  @override
  CompHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompHistoryEntry(
      date: fields[0] as DateTime,
      event: fields[1] as String,
      score: fields[2] as int,
      xCount: fields[3] as int,
      position: fields[4] as int,
      totalShooters: fields[5] as int,
      finalResults: (fields[6] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
    );
  }

  @override
  void write(BinaryWriter writer, CompHistoryEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.event)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.xCount)
      ..writeByte(4)
      ..write(obj.position)
      ..writeByte(5)
      ..write(obj.totalShooters)
      ..writeByte(6)
      ..write(obj.finalResults);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
