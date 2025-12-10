// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firearm_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FirearmEntryAdapter extends TypeAdapter<FirearmEntry> {
  @override
  final int typeId = 2;

  @override
  FirearmEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FirearmEntry(
      id: fields[0] as String,
      make: fields[1] as String,
      model: fields[2] as String,
      caliber: fields[3] as String,
      owned: fields[4] as bool,
      scopeSize: fields[5] as String?,
      notes: fields[6] as String?,
      imagePath: fields[7] as String?,
      thumbnailPath: fields[8] as String?,
      nickname: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FirearmEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.make)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.caliber)
      ..writeByte(4)
      ..write(obj.owned)
      ..writeByte(5)
      ..write(obj.scopeSize)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.thumbnailPath)
      ..writeByte(9)
      ..write(obj.nickname);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirearmEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
