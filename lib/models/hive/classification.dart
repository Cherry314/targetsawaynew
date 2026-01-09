import 'package:hive/hive.dart';

part 'classification.g.dart';

@HiveType(typeId: 113)
class Classification extends HiveObject {
  @HiveField(0)
  String className; // Always required - class name

  @HiveField(1)
  int? min; // Optional - minimum percentage

  @HiveField(2)
  int? max; // Optional - maximum percentage

  Classification({
    required this.className,
    this.min,
    this.max,
  });
}
