import 'package:hive/hive.dart';

part 'procedural_penalty.g.dart';

@HiveType(typeId: 112)
class ProceduralPenalty extends HiveObject {
  @HiveField(0)
  String? title; // Optional - penalty title

  @HiveField(1)
  String? text; // Optional - detailed penalty description

  @HiveField(2)
  String? idx; // Optional - index identifier

  @HiveField(3)
  String? idxText; // Optional - index text

  ProceduralPenalty({
    this.title,
    this.text,
    this.idx,
    this.idxText,
  });
}
