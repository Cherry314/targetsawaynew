// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firearm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FirearmAdapter extends TypeAdapter<Firearm> {
  @override
  final int typeId = 104;

  @override
  Firearm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Firearm(
      id: fields[0] as int,
      code: fields[1] as String,
      gunType: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Firearm obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.gunType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirearmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
