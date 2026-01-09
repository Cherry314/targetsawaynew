import 'package:hive/hive.dart';

part 'target.g.dart';

@HiveType(typeId: 105)
class Target extends HiveObject {
  @HiveField(0)
  String? title; // Optional - target identifier

  @HiveField(1)
  String? text; // Optional - only show if provided

  @HiveField(2)
  String? link; // Optional - link to view target image/PDF

  @HiveField(3)
  int? qtyNeeded; // Optional - quantity needed for match

  Target({
    this.title,
    this.text,
    this.link,
    this.qtyNeeded,
  });
}
