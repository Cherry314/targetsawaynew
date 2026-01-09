import 'package:hive/hive.dart';

part 'position.g.dart';

@HiveType(typeId: 108)
class Position extends HiveObject {
  @HiveField(0)
  String? title; // Optional - position identifier

  @HiveField(1)
  String? text; // Optional - detailed description

  Position({
    this.title,
    this.text,
  });
}
