import 'package:hive/hive.dart';

part 'range_equipment.g.dart';

@HiveType(typeId: 124)
class RangeEquipment extends HiveObject {
  @HiveField(0)
  String? title; // Optional - range equipment title

  @HiveField(1)
  String? text; // Optional - detailed range equipment information

  RangeEquipment({
    this.title,
    this.text,
  });
}
