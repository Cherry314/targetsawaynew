// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procedural_penalty.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProceduralPenaltyAdapter extends TypeAdapter<ProceduralPenalty> {
  @override
  final int typeId = 112;

  @override
  ProceduralPenalty read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProceduralPenalty(
      title: fields[0] as String?,
      text: fields[1] as String?,
      idx: fields[2] as String?,
      idxText: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProceduralPenalty obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.idx)
      ..writeByte(3)
      ..write(obj.idxText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProceduralPenaltyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
