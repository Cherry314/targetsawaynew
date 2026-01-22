import 'package:hive/hive.dart';

part 'target_zone.g.dart';

@HiveType(typeId: 131)
class TargetZone extends HiveObject {
  @HiveField(0)
  String score; // Zone score (e.g., "9", "10", "X")

  @HiveField(1)
  double? min; // Minimum diameter in cm (optional)

  @HiveField(2)
  double? max; // Maximum diameter in cm (optional)

  @HiveField(3)
  String? rot; // Rotation information (optional)

  @HiveField(4)
  String? notes; // Additional notes (optional)

  TargetZone({
    required this.score,
    this.min,
    this.max,
    this.rot,
    this.notes,
  });

  // Helper method to format the zone range
  String get rangeDescription {
    if (min != null && max != null) {
      return '$min cm - $max cm';
    } else if (min != null) {
      return 'From $min cm';
    } else if (max != null) {
      return 'Up to $max cm';
    }
    return 'No range specified';
  }

  // Check if a diameter falls within this zone
  bool containsDiameter(double diameter) {
    if (min == null && max == null) return false;
    if (min == null) return diameter <= max!;
    if (max == null) return diameter >= min!;
    return diameter >= min! && diameter <= max!;
  }
}
