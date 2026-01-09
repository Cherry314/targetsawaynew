// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassificationAdapter extends TypeAdapter<Classification> {
  @override
  final int typeId = 113;

  @override
  Classification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Classification(
      className: fields[0] as String,
      min: fields[1] as int?,
      max: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Classification obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.className)
      ..writeByte(1)
      ..write(obj.min)
      ..writeByte(2)
      ..write(obj.max);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
