import 'package:hive/hive.dart';

part 'magazine.g.dart';

@HiveType(typeId: 121)
class Magazine extends HiveObject {
  @HiveField(0)
  String? title; // Optional - magazine title

  @HiveField(1)
  String? text; // Optional - detailed magazine information

  Magazine({
    this.title,
    this.text,
  });
}
