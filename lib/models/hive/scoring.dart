import 'package:hive/hive.dart';

part 'scoring.g.dart';

@HiveType(typeId: 119)
class Scoring extends HiveObject {
  @HiveField(0)
  String? title; // Optional - scoring title

  @HiveField(1)
  String? text; // Optional - detailed scoring information

  Scoring({
    this.title,
    this.text,
  });
}
