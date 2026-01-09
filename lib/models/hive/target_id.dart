import 'package:hive/hive.dart';
import 'zone.dart';

part 'target_id.g.dart';

@HiveType(typeId: 126)
class TargetID extends HiveObject {
  @HiveField(0)
  String? title; // Optional - target ID identifier

  @HiveField(1)
  String? imageLocation; // Optional - path to image

  @HiveField(2)
  List<Zone>? zones; // Optional - scoring zones

  TargetID({
    this.title,
    this.imageLocation,
    this.zones,
  });
}
