// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_card_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MembershipCardEntryAdapter extends TypeAdapter<MembershipCardEntry> {
  @override
  final int typeId = 3;

  @override
  MembershipCardEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MembershipCardEntry(
      id: fields[0] as String,
      memberName: fields[1] as String,
      cardNumber: fields[2] as String?,
      frontImagePath: fields[3] as String?,
      backImagePath: fields[4] as String?,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MembershipCardEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberName)
      ..writeByte(2)
      ..write(obj.cardNumber)
      ..writeByte(3)
      ..write(obj.frontImagePath)
      ..writeByte(4)
      ..write(obj.backImagePath)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipCardEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
