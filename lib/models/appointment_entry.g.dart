// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppointmentEntryAdapter extends TypeAdapter<AppointmentEntry> {
  @override
  final int typeId = 4;

  @override
  AppointmentEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dateTime: fields[3] as DateTime,
      notifyOneDay: fields[4] as bool,
      notifyOneWeek: fields[5] as bool,
      oneDayNotificationId: fields[6] as int?,
      oneWeekNotificationId: fields[7] as int?,
      linkedScoreId: fields[8] as String?,
      isScoreEntry: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.notifyOneDay)
      ..writeByte(5)
      ..write(obj.notifyOneWeek)
      ..writeByte(6)
      ..write(obj.oneDayNotificationId)
      ..writeByte(7)
      ..write(obj.oneWeekNotificationId)
      ..writeByte(8)
      ..write(obj.linkedScoreId)
      ..writeByte(9)
      ..write(obj.isScoreEntry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
