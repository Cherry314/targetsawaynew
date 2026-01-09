import 'package:hive/hive.dart';

part 'tie.g.dart';

@HiveType(typeId: 111)
class Tie extends HiveObject {
  @HiveField(0)
  String? title; // Optional - tie title

  @HiveField(1)
  String? text; // Optional - detailed explanation

  @HiveField(2)
  String? idx; // Optional - index identifier

  @HiveField(3)
  String? idxText; // Optional - index text

  Tie({
    this.title,
    this.text,
    this.idx,
    this.idxText,
  });
}
