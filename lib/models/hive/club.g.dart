// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClubAdapter extends TypeAdapter<Club> {
  @override
  final int typeId = 133;

  @override
  Club read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Club(
      clubname: fields[0] as String,
      renewalDate: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Club obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.clubname)
      ..writeByte(1)
      ..write(obj.renewalDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClubAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
