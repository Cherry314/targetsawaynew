// lib/models/firearm_entry.dart
import 'package:hive/hive.dart';

part 'firearm_entry.g.dart'; // kept for compatibility if you want to use codegen later

@HiveType(typeId: 2)
class FirearmEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String make;

  @HiveField(2)
  String model;

  @HiveField(3)
  String caliber;

  @HiveField(4)
  bool owned;

  @HiveField(5)
  String? scopeSize;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  String? imagePath;

  @HiveField(8)
  String? thumbnailPath;

  @HiveField(9)
  String? nickname;

  FirearmEntry({
    required this.id,
    required this.make,
    required this.model,
    required this.caliber,
    this.owned = false,
    this.scopeSize,
    this.notes,
    this.imagePath,
    this.thumbnailPath,
    this.nickname,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'caliber': caliber,
    'owned': owned,
    'scopeSize': scopeSize,
    'notes': notes,
    'imagePath': imagePath,
    'thumbnailPath': thumbnailPath,
    'nickname': nickname,
  };

  /// Create from JSON
  factory FirearmEntry.fromJson(Map<String, dynamic> json) => FirearmEntry(
    id: json['id'],
    make: json['make'],
    model: json['model'],
    caliber: json['caliber'],
    owned: json['owned'] ?? false,
    scopeSize: json['scopeSize'],
    notes: json['notes'],
    imagePath: json['imagePath'],
    thumbnailPath: json['thumbnailPath'],
    nickname: json['nickname'],
  );
}
