import 'package:hive/hive.dart';

part 'loading.g.dart';

@HiveType(typeId: 120)
class Loading extends HiveObject {
  @HiveField(0)
  String? title; // Optional - loading title

  @HiveField(1)
  String? text; // Optional - detailed loading information

  Loading({
    this.title,
    this.text,
  });
}
