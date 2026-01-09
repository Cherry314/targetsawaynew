// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'range_equipment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RangeEquipmentAdapter extends TypeAdapter<RangeEquipment> {
  @override
  final int typeId = 124;

  @override
  RangeEquipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RangeEquipment(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RangeEquipment obj) {
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
      other is RangeEquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
