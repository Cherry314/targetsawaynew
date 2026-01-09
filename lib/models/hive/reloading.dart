import 'package:hive/hive.dart';

part 'reloading.g.dart';

@HiveType(typeId: 122)
class Reloading extends HiveObject {
  @HiveField(0)
  String? title; // Optional - reloading title

  @HiveField(1)
  String? text; // Optional - detailed reloading information

  Reloading({
    this.title,
    this.text,
  });
}
