import 'package:hive/hive.dart';

part 'target_position.g.dart';

@HiveType(typeId: 114)
class TargetPosition extends HiveObject {
  @HiveField(0)
  String? title; // Optional - target position title

  @HiveField(1)
  String? text; // Optional - location details

  TargetPosition({
    this.title,
    this.text,
  });
}
