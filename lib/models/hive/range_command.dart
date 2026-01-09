import 'package:hive/hive.dart';

part 'range_command.g.dart';

@HiveType(typeId: 110)
class RangeCommand extends HiveObject {
  @HiveField(0)
  String? title; // Optional - range command title

  @HiveField(1)
  String? text; // Optional - detailed explanation

  RangeCommand({
    this.title,
    this.text,
  });
}
