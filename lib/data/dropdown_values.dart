// lib/data/dropdown_values.dart
import 'package:hive/hive.dart';
import '../models/hive/event.dart';

class DropdownValues {
  // Freestyle constant - always available at the top of the list
  static const String freestyle = 'Freestyle';
  
  // Internal list for user-selected favorite practices (without 'All')
  // Starts empty - users should select favorites from the full events list
  static List<String> _favoritePractices = [];

  // Getter that returns favorites, or empty string if no favorites
  // Returns a new list each time to prevent external modifications
  static List<String> get practices {
    // Always return Freestyle at the top, then favorites or empty string
    if (_favoritePractices.isEmpty) {
      return [freestyle, ''];
    }

    return [freestyle, ..._favoritePractices];
  }

  // Setter to update favorite practices (removes 'All' and 'Freestyle' if present)
  static set practices(List<String> value) {
    // Filter out 'All' and 'Freestyle' (it's always added by getter) and remove any duplicates
    final filtered = value.where((p) => p != 'All' && p != freestyle).toSet().toList();
    _favoritePractices = filtered;
  }

  // Internal list for user-selected favorite calibers
  static List<String> _favoriteCalibers = [];

  // Getter for favorite calibers
  static List<String> get calibers {
    if (_favoriteCalibers.isEmpty) {
      return [''];
    }
    return [..._favoriteCalibers];
  }

  // Setter to update favorite calibers
  static set calibers(List<String> value) {
    _favoriteCalibers = value.where((c) => c.isNotEmpty).toList();
  }

  // Internal list for user-selected favorite firearm IDs (stores the actual ID integers)
  static List<int> _favoriteFirearmIds = [];

  // Getter for favorite firearm codes (returns display strings)
  static List<String> get firearmIds {
    if (_favoriteFirearmIds.isEmpty) {
      return [''];
    }
    // Map IDs to codes for display (no empty string if we have favorites)
    return _favoriteFirearmIds.map((id) {
      final info = masterFirearmTable.firstWhere(
        (f) => f.id == id,
        orElse: () => FirearmInfo(id: id, code: 'Unknown', gunType: ''),
      );
      return info.code;
    }).toList();
  }

  // Setter to update favorite firearm IDs
  static set favoriteFirearmIds(List<int> value) {
    _favoriteFirearmIds = value;
  }

  // Get list of favorite firearm IDs (for internal use)
  static List<int> get favoriteFirearmIdsList => List.from(_favoriteFirearmIds);

  // Get firearm ID by code
  static int? getFirearmIdByCode(String code) {
    if (code.isEmpty) return null;
    try {
      final info = masterFirearmTable.firstWhere((f) => f.code == code);
      return info.id;
    } catch (e) {
      return null;
    }
  }

  // Get firearm code by ID
  static String? getFirearmCodeById(int id) {
    try {
      final info = masterFirearmTable.firstWhere((f) => f.id == id);
      return info.code;
    } catch (e) {
      return null;
    }
  }

  // Default fallback list for master practices
  static const List<String> _defaultMasterPractices = [
    '25m Precision',
    '25m Precision Muzzle Loading',
    '25m Precision Benched',
    '50m Precision',
    '50m Precision',
    '50m Precision Muzzle Loading',
    '50m Precision Benched',
    'America Match',
    'Timed & Precision 1',
    'Timed & Precision 1 Air Piston',
    'Timed & Precision 1 Shotgun',
    'Timed & Precision 1 Shotgun Classic',
    'Timed & Precision 1 Muzzle Loading',
    'Timed & Precision 2',
    'Timed & Precision 3',
    'Multi Target',
    'Multi-Target Shotgun',
    'Multi-Target Muzzle Loading Revolver',
    'Phoenix A',
    'Multi-Target 3',
    '1500',
    '1020',
    'Bianchi',
    'WA48',
    'Advancing Target Muzzle Loading Revolver',
    'Advancing Target Benched',
    'Speed Steels Challenge',
    'Speed Steels Challenge Benched',
    '25m Timed',
    '25m Timed Muzzle Loading Revolver',
    'Sport Pistol',
    'NRA Rapid Fire Pistol',
    'Standard Pistol',
    'The Grand',
    'NRA Embassy Cup',
    'Service Match',
    'Man v Man',
    'Metallic Silhouettes',
    '25m Classic Muzzle Loading',
    'Granet',
    'Granet Muzzle Loading',
    'Imperial Silhouettes',
    'Surrenden',
    '100 Yards Muzzle Loading',
    '100/200 Yards',
    '200/300 Yards',
    'IGRF Limited Bolt Action Rifle',
    'Sporting Rifle Statics',
    '100/200/300 Yards',
    '100/200/300 Yards Sporting',
    '400/500/600 Yards',
    '400/500/600 Yards F Class',
    '400/500/600 Yards Black Powder',
    '800/900/1000 Yards',
    '800/900/1000 Yards F Class',
    '800/900/1000 Yards Black Powder',
    '200 Yards',
    'Mini McQueen',
    'McQueen',
    '25m Precision Unlimited',
    'Advancing Target Unlimited',
    'Cotterill Unlimited',
    'Imperial Silhouettes Unlimited',
    'Timed & Precision 1 Unlimited',
    'Advance Target Team',
    'Lord Salisbury Team',
    'Peel Cup',
  ];

  /// Get master practices list from Hive Event names, or use default list as fallback
  static List<String> get masterPractices {
    try {
      // Try to open the events box
      if (Hive.isBoxOpen('events')) {
        final eventBox = Hive.box<Event>('events');
        
        // If box is empty, use default list
        if (eventBox.isEmpty) {
          return List.from(_defaultMasterPractices);
        }

        // Extract event names from Hive in insertion order
        final eventNames = <String>[];
        final seenNames = <String>{};

        for (final event in eventBox.values) {
          // Only add if not already seen (removes duplicates while preserving order)
          if (!seenNames.contains(event.name)) {
            eventNames.add(event.name);
            seenNames.add(event.name);
          }
        }

        return eventNames;
      } else {
        // Box not open yet, use default list
        return List.from(_defaultMasterPractices);
      }
    } catch (e) {
      // If any error occurs, fall back to default list
      return List.from(_defaultMasterPractices);
    }
  }

  // Master firearm table - complete list of all available firearms
  static const List<FirearmInfo> masterFirearmTable = [
    FirearmInfo(id: 1, code: 'GRSB', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 2, code: 'GRCF', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 3, code: 'GRCF Open', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 4, code: 'GRCF Classic', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 7, code: 'GRCF Issued', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 21, code: 'LBP', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 22, code: 'LBR', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 23, code: 'AP', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 24, code: 'LBP - Iron Sight', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 25, code: 'LBR - Iron Sight', gunType: 'Gallery Rifle & Pistol'),
    FirearmInfo(id: 30, code: 'SGSV', gunType: 'Shotgun'),
    FirearmInfo(id: 31, code: 'SGMB', gunType: 'Shotgun'),
    FirearmInfo(id: 34, code: 'SG', gunType: 'Shotgun'),
    FirearmInfo(id: 35, code: 'SGM', gunType: 'Shotgun'),
    FirearmInfo(id: 36, code: 'SGSA', gunType: 'Shotgun'),
    FirearmInfo(id: 37, code: 'SGC', gunType: 'Shotgun'),
    FirearmInfo(id: 41, code: 'MLP', gunType: 'Muzzle Loading'),
    FirearmInfo(id: 42, code: 'MLR', gunType: 'Muzzle Loading'),
    FirearmInfo(id: 62, code: 'Hunter Classic', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 63, code: 'Free Pistol A', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 65, code: 'Production Free Pistol A', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 66, code: 'Production Free Pistol B', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 67, code: 'Allcomer Revolver', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 68, code: 'Free Pistol', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 69, code: 'Production Free Revolver', gunType: 'Long Range Pistol'),
    FirearmInfo(id: 80, code: 'Any Fullbore Rifle', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 81, code: 'SR(a) Pre-1955', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 82, code: 'SR(b) Pre-1955', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 83, code: 'SR Open Pre-1955', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 84, code: 'Bolt Action Centerfire Rifle', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 85, code: 'Sporting Rifle', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 86, code: 'F Class', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 87, code: 'Black Powder Cartridge', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 88, code: 'FTR', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 90, code: 'Issued Sniper Rifle', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 91, code: 'SR Post 1955 Iron Sight', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 92, code: 'SR Post 1955 Service Optic', gunType: 'Fullbore Rifle'),
    FirearmInfo(id: 93, code: 'SR Post 1955 Practical Optic', gunType: 'Fullbore Rifle'),
  ];
}

/// FirearmInfo class - represents a firearm with ID, code, and gun type
class FirearmInfo {
  final int id;
  final String code;
  final String gunType;

  const FirearmInfo({
    required this.id,
    required this.code,
    required this.gunType,
  });
}
