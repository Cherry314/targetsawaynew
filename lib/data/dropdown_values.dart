// lib/data/dropdown_values.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/hive/event.dart';

class DropdownValues {
  // Internal list for user-selected favorite practices (without 'All')
  // Starts empty - users should select favorites from the full events list
  static List<String> _favoritePractices = [];

  // Getter that always returns 'All' at the top followed by favorites
  // Returns a new list each time to prevent external modifications
  static List<String> get practices {
    debugPrint('DEBUG practices getter called');
    debugPrint('  _favoritePractices: $_favoritePractices');
    debugPrint('  Contains All? ${_favoritePractices.contains('All')}');

    // Debug: Ensure _favoritePractices doesn't contain 'All'
    assert(!_favoritePractices.contains('All'),
    'Internal error: _favoritePractices contains "All"');

    final result = ['', ..._favoritePractices];
    debugPrint('  Returning: $result');
    debugPrint('  Count of "All": ${result
        .where((e) => e == 'All')
        .length}');
    return result;
  }

  // Setter to update favorite practices (removes 'All' if present)
  static set practices(List<String> value) {
    // Filter out 'All' and remove any duplicates
    final filtered = value.where((p) => p != 'All').toSet().toList();
    debugPrint('DEBUG DropdownValues.practices setter:');
    debugPrint('  Input: $value');
    debugPrint('  Filtered: $filtered');
    debugPrint('  Stack: ${StackTrace.current}');
    _favoritePractices = filtered;
  }

  static List<String> calibers = [
    'All',
    '.22',
    '.357',
    '9mm',
    '7.62mm',
    // add more here
  ];

  static List<String> firearmIds = [
    'All',
    'GRSB',
    'GRCF',
    'GFCF Open',
    'GFCF Classic',
    'LBP',
    'LBR',
  ];

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
          debugPrint('Events box is empty, using default master practices');
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
        
        debugPrint('Loaded ${eventNames.length} master practices from Hive');
        return eventNames;
      } else {
        // Box not open yet, use default list
        debugPrint('Events box not open, using default master practices');
        return List.from(_defaultMasterPractices);
      }
    } catch (e) {
      // If any error occurs, fall back to default list
      debugPrint('Error loading master practices from Hive: $e');
      return List.from(_defaultMasterPractices);
    }
  }


}
