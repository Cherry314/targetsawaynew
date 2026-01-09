// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sighters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SightersAdapter extends TypeAdapter<Sighters> {
  @override
  final int typeId = 117;

  @override
  Sighters read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sighters(
      text: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Sighters obj) {
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
      other is SightersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
