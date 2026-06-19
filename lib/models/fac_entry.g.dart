// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fac_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FacEntryAdapter extends TypeAdapter<FacEntry> {
  @override
  final int typeId = 137;

  @override
  FacEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FacEntry(
      id: fields[0] as String,
      certificateNumber: fields[1] as String?,
      validFrom: fields[2] as DateTime?,
      validTo: fields[3] as DateTime?,
      firearms: (fields[4] as List?)?.cast<FacFirearmAllowance>() ?? [],
      ammunition: (fields[5] as List?)?.cast<FacAmmunitionAllowance>() ?? [],
      firearmsOwned: (fields[6] as List?)?.cast<FacFirearmOwned>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, FacEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.certificateNumber)
      ..writeByte(2)
      ..write(obj.validFrom)
      ..writeByte(3)
      ..write(obj.validTo)
      ..writeByte(4)
      ..write(obj.firearms)
      ..writeByte(5)
      ..write(obj.ammunition)
      ..writeByte(6)
      ..write(obj.firearmsOwned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FacFirearmAllowanceAdapter extends TypeAdapter<FacFirearmAllowance> {
  @override
  final int typeId = 138;

  @override
  FacFirearmAllowance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FacFirearmAllowance(
      calibre: fields[0] as String?,
      type: fields[1] as String?,
      action: fields[2] as String?,
      qty: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, FacFirearmAllowance obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.calibre)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.qty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacFirearmAllowanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FacAmmunitionAllowanceAdapter extends TypeAdapter<FacAmmunitionAllowance> {
  @override
  final int typeId = 139;

  @override
  FacAmmunitionAllowance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FacAmmunitionAllowance(
      calibre: fields[0] as String?,
      quantity: fields[1] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, FacAmmunitionAllowance obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.calibre)
      ..writeByte(1)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacAmmunitionAllowanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FacFirearmOwnedAdapter extends TypeAdapter<FacFirearmOwned> {
  @override
  final int typeId = 140;

  @override
  FacFirearmOwned read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FacFirearmOwned(
      calibre: fields[0] as String?,
      makersName: fields[1] as String?,
      type: fields[2] as String?,
      action: fields[3] as String?,
      identification: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FacFirearmOwned obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.calibre)
      ..writeByte(1)
      ..write(obj.makersName)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.identification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacFirearmOwnedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
