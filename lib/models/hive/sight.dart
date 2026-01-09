import 'package:hive/hive.dart';

part 'sight.g.dart';

@HiveType(typeId: 107)
class Sight extends HiveObject {
  @HiveField(0)
  String? text; // Optional - sight description/requirements

  Sight({
    this.text,
  });
}
