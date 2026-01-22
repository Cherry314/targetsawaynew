import 'package:hive/hive.dart';
import 'target_zone.dart';

part 'target_info.g.dart';

@HiveType(typeId: 132)
class TargetInfo extends HiveObject {
  @HiveField(0)
  String targetName; // Name/identifier of the target (e.g., "ISSF 10m Air Rifle")

  @HiveField(1)
  String? imageLocation; // Path or URL to target image

  @HiveField(2)
  String? notes; // General notes about this target

  @HiveField(3)
  List<TargetZone> zones; // List of scoring zones for this target

  TargetInfo({
    required this.targetName,
    this.imageLocation,
    this.notes,
    required this.zones,
  });

  // Helper method to get number of zones
  int get zoneCount => zones.length;

  // Helper method to find zone by score
  TargetZone? getZoneByScore(String score) {
    try {
      return zones.firstWhere((zone) => zone.score == score);
    } catch (e) {
      return null;
    }
  }

  // Helper method to find which zone a diameter falls into
  TargetZone? getZoneForDiameter(double diameter) {
    try {
      return zones.firstWhere((zone) => zone.containsDiameter(diameter));
    } catch (e) {
      return null;
    }
  }

  // Sort zones by score (descending - highest score first)
  void sortZonesByScore() {
    zones.sort((a, b) {
      // Handle X as highest score
      if (a.score.toUpperCase() == 'X') return -1;
      if (b.score.toUpperCase() == 'X') return 1;
      
      // Try to parse as numbers
      final aNum = int.tryParse(a.score);
      final bNum = int.tryParse(b.score);
      
      if (aNum != null && bNum != null) {
        return bNum.compareTo(aNum); // Descending order
      }
      
      return a.score.compareTo(b.score);
    });
  }
}
