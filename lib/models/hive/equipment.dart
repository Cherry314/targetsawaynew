import 'package:hive/hive.dart';

part 'equipment.g.dart';

@HiveType(typeId: 123)
class Equipment extends HiveObject {
  @HiveField(0)
  String? title; // Optional - equipment title

  @HiveField(1)
  String? text; // Optional - detailed equipment information

  Equipment({
    this.title,
    this.text,
  });
}
