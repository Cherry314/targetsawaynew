// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SightAdapter extends TypeAdapter<Sight> {
  @override
  final int typeId = 107;

  @override
  Sight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sight(
      text: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sight obj) {
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
      other is SightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
