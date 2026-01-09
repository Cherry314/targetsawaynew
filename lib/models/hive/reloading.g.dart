// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reloading.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReloadingAdapter extends TypeAdapter<Reloading> {
  @override
  final int typeId = 122;

  @override
  Reloading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reloading(
      title: fields[0] as String?,
      text: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Reloading obj) {
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
      other is ReloadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
