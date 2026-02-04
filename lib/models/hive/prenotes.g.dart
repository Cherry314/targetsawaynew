// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prenotes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PreNotesAdapter extends TypeAdapter<PreNotes> {
  @override
  final int typeId = 36;

  @override
  PreNotes read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PreNotes(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PreNotes obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.text);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreNotesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
