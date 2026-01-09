import 'package:hive/hive.dart';

part 'ammunition.g.dart';

@HiveType(typeId: 106)
class Ammunition extends HiveObject {
  @HiveField(0)
  String? title; // Optional - ammunition title

  @HiveField(1)
  String? text; // Optional - ammunition description

  Ammunition({
    this.title,
    this.text,
  });
}
