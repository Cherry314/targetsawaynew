import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hive/event.dart';
import '../models/hive/event_content.dart';
import '../models/hive/event_override.dart';
import '../models/hive/override_content.dart';
import '../models/hive/firearm.dart';
import '../models/hive/target.dart';
import '../models/hive/ammunition.dart';
import '../models/hive/sight.dart';
import '../models/hive/position.dart';
import '../models/hive/ready_position.dart';
import '../models/hive/practice.dart';
import '../models/hive/stage.dart';
import '../models/hive/course_of_fire.dart';
import '../models/hive/event_notes.dart';
import '../models/hive/sighters.dart';
import '../models/hive/notes.dart';
import '../models/hive/scoring.dart';
import '../models/hive/loading.dart';
import '../models/hive/magazine.dart';
import '../models/hive/reloading.dart';
import '../models/hive/equipment.dart';
import '../models/hive/range_equipment.dart';
import '../models/hive/changing_position.dart';
import '../models/hive/range_command.dart';
import '../models/hive/tie.dart';
import '../models/hive/procedural_penalty.dart';
import '../models/hive/classification.dart';

class DataImporter {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Collection names (must match FirestoreService)
  static const String eventsCollection = 'events';
  static const String firearmsCollection = 'firearms';

  /// Import all data from Firestore into Hive
  /// This will DELETE all existing Hive data and replace it with Firestore data
  /// Returns a map with counts of imported items
  Future<Map<String, int>> importAllData() async {
    final results = <String, int>{};

    try {
      // Step 1: Clear all Hive data
      await _clearAllHiveData();

      // Step 2: Import firearms first (events reference them)
      final firearmCount = await _importFirearms();
      results['firearms'] = firearmCount;

      // Step 3: Import events
      final eventCount = await _importEvents();
      results['events'] = eventCount;
    } catch (e) {
      results['error'] = -1;
      debugPrint('Error during import: $e');
      rethrow;
    }

    return results;
  }

  /// Clear all Hive data (events and firearms)
  Future<void> _clearAllHiveData() async {
    // Clear events box
    final eventBox = Hive.box<Event>('events');
    await eventBox.clear();

    // Clear firearms box
    final firearmBox = Hive.box<Firearm>('firearms_hive');
    await firearmBox.clear();
  }

  /// Import all firearms from Firestore
  /// Returns the number of firearms imported
  Future<int> _importFirearms() async {
    final firearmBox = Hive.box<Firearm>('firearms_hive');
    final firestoreFirearms = await _firestore.collection(firearmsCollection).get();

    int importedCount = 0;

    for (final doc in firestoreFirearms.docs) {
      try {
        final firearm = _mapToFirearm(doc.data(), doc.id);
        await firearmBox.put(firearm.id, firearm);
        importedCount++;
      } catch (e) {
        debugPrint('Error importing firearm with doc ID ${doc.id}: $e');
      }
    }

    return importedCount;
  }

  /// Import all events from Firestore
  /// Returns the number of events imported
  Future<int> _importEvents() async {
    final eventBox = Hive.box<Event>('events');
    final firestoreEvents = await _firestore.collection(eventsCollection).get();

    int importedCount = 0;

    for (final doc in firestoreEvents.docs) {
      try {
        final event = _mapToEvent(doc.data());
        await eventBox.put(event.eventNumber, event);
        importedCount++;
      } catch (e) {
        debugPrint('Error importing event with doc ID ${doc.id}: $e');
      }
    }

    return importedCount;
  }

  // ========== Conversion Methods (Firestore Map -> Hive Objects) ==========

  /// Convert Firestore map to Firearm object
  Firearm _mapToFirearm(Map<String, dynamic> data, String docId) {
    return Firearm(
      id: data['id'] as int,
      code: data['code'] as String,
      gunType: data['gunType'] as String,
    );
  }

  /// Convert Firestore map to Event object
  Event _mapToEvent(Map<String, dynamic> data) {
    return Event(
      eventNumber: data['eventNumber'] as int,
      name: data['name'] as String,
      applicableFirearmIds: List<int>.from(data['applicableFirearmIds'] ?? []),
      baseContent: _mapToEventContent(data['baseContent'] as Map<String, dynamic>? ?? {}),
      overrides: _mapToEventOverrides(data['overrides'] as List<dynamic>? ?? []),
    );
  }

  /// Convert Firestore map to EventContent object
  EventContent _mapToEventContent(Map<String, dynamic> data) {
    final content = EventContent(
      targets: _mapToTargets(data['targets'] as List<dynamic>? ?? []),
      ammunition: _mapToAmmunition(data['ammunition'] as List<dynamic>?),
      sights: _mapToSights(data['sights'] as List<dynamic>? ?? []),
      positions: _mapToPositions(data['positions'] as List<dynamic>? ?? []),
      readyPositions: _mapToReadyPositions(data['readyPositions'] as List<dynamic>? ?? []),
      rangeCommands: _mapToRangeCommands(data['rangeCommands'] as List<dynamic>? ?? []),
      notes: _mapToEventNotes(data['notes'] as List<dynamic>?),
      ties: _mapToTies(data['ties'] as List<dynamic>?),
      proceduralPenalties: _mapToProceduralPenalties(data['proceduralPenalties'] as List<dynamic>?),
      classifications: _mapToClassifications(data['classifications'] as List<dynamic>?),
      targetPositions: null, // Not stored in Firestore
      courseOfFire: data['courseOfFire'] != null
          ? _mapToCourseOfFire(data['courseOfFire'] as Map<String, dynamic>)
          : CourseOfFire(distance: null, totalTime: null, totalRounds: null, maxScore: null),
      sighters: _mapToSighters(data['sighters'] as List<dynamic>?),
      practices: data['practices'] != null
          ? _mapToPractices(data['practices'] as List<dynamic>)
          : [],
      targetIds: null, // Not stored in Firestore
      generalNotes: _mapToNotes(data['generalNotes'] as Map<String, dynamic>?),
      scoring: _mapToScoring(data['scoring'] as Map<String, dynamic>?),
      loading: _mapToLoading(data['loading'] as Map<String, dynamic>?),
      magazine: _mapToMagazines(data['magazine'] as List<dynamic>?),
      reloading: _mapToReloading(data['reloading'] as Map<String, dynamic>?),
      equipment: _mapToEquipment(data['equipment'] as Map<String, dynamic>?),
      rangeEquipment: _mapToRangeEquipment(data['rangeEquipment'] as Map<String, dynamic>?),
      changingPosition: _mapToChangingPosition(data['changingPosition'] as Map<String, dynamic>?),
    );

    // Debug output
    debugPrint('EventContent Debug:');
    debugPrint('  Targets: ${content.targets.length}');
    debugPrint('  Sights: ${content.sights.length}');
    debugPrint('  Positions: ${content.positions.length}');
    debugPrint('  ReadyPositions: ${content.readyPositions.length}');
    debugPrint('  Sighters: ${content.sighters?.length ?? 0}');
    debugPrint('  Practices: ${content.practices.length}');

    return content;
  }

  /// Convert Firestore map to OverrideContent object
  OverrideContent _mapToOverrideContent(Map<String, dynamic> data) {
    return OverrideContent(
      targets: data['targets'] != null
          ? _mapToTargets(data['targets'] as List<dynamic>? ?? [])
          : null,
      ammunition: _mapToAmmunition(data['ammunition'] as List<dynamic>?),
      sights: data['sights'] != null
          ? _mapToSights(data['sights'] as List<dynamic>? ?? [])
          : null,
      positions: data['positions'] != null
          ? _mapToPositions(data['positions'] as List<dynamic>? ?? [])
          : null,
      readyPositions: data['readyPositions'] != null
          ? _mapToReadyPositions(data['readyPositions'] as List<dynamic>? ?? [])
          : null,
      rangeCommands: data['rangeCommands'] != null
          ? _mapToRangeCommands(data['rangeCommands'] as List<dynamic>? ?? [])
          : null,
      notes: _mapToEventNotes(data['notes'] as List<dynamic>?),
      ties: _mapToTies(data['ties'] as List<dynamic>?),
      proceduralPenalties: _mapToProceduralPenalties(data['proceduralPenalties'] as List<dynamic>?),
      classifications: _mapToClassifications(data['classifications'] as List<dynamic>?),
      targetPositions: null,
      courseOfFire: data['courseOfFire'] != null
          ? _mapToCourseOfFire(data['courseOfFire'] as Map<String, dynamic>)
          : null,
      sighters: _mapToSighters(data['sighters'] as List<dynamic>?),
      practices: data['practices'] != null
          ? _mapToPractices(data['practices'] as List<dynamic>)
          : null,
      targetIds: null,
      generalNotes: _mapToNotes(data['generalNotes'] as Map<String, dynamic>?),
      scoring: _mapToScoring(data['scoring'] as Map<String, dynamic>?),
      loading: _mapToLoading(data['loading'] as Map<String, dynamic>?),
      reloading: _mapToReloading(data['reloading'] as Map<String, dynamic>?),
      equipment: _mapToEquipment(data['equipment'] as Map<String, dynamic>?),
      rangeEquipment: _mapToRangeEquipment(data['rangeEquipment'] as Map<String, dynamic>?),
      changingPosition: _mapToChangingPosition(data['changingPosition'] as Map<String, dynamic>?),
    );
  }

  /// Convert Firestore list to EventOverride objects
  List<EventOverride> _mapToEventOverrides(List<dynamic> overrides) {
    return overrides.map((overrideData) {
      if (overrideData is Map<String, dynamic>) {
        return EventOverride(
          firearmIds: List<int>.from(overrideData['firearmIds'] ?? []),
          changes: _mapToOverrideContent(overrideData['changes'] as Map<String, dynamic>? ?? {}),
        );
      }
      return EventOverride(firearmIds: [], changes: OverrideContent());
    }).toList();
  }

  /// Convert Firestore list to targets to see what's being read
  List<Target> _mapToTargets(List<dynamic> targets) {
    debugPrint('Raw targets data from Firebase: $targets');
    return targets.map((targetData) {
      if (targetData is Map<String, dynamic>) {
        return Target(
          title: targetData['title'] as String?,
          text: targetData['text'] as String?,
          link: targetData['link'] as String?,
          qtyNeeded: targetData['qtyNeeded'] as int?,
        );
      }
      return Target();
    }).toList();
  }

  /// Convert Firestore list to Ammunition objects
  List<Ammunition>? _mapToAmmunition(List<dynamic>? ammunitionList) {
    if (ammunitionList == null) return null;
    return ammunitionList.map((ammoData) {
      if (ammoData is Map<String, dynamic>) {
        return Ammunition(
          title: ammoData['title'] as String?,
          text: ammoData['text'] as String?,
        );
      }
      return Ammunition();
    }).toList();
  }

  /// Convert Firestore list to Sight objects
  List<Sight> _mapToSights(List<dynamic> sights) {
    return sights.map((sightData) {
      if (sightData is Map<String, dynamic>) {
        return Sight(
          text: sightData['text'] as String?,
        );
      }
      return Sight();
    }).toList();
  }

  /// Convert Firestore list to Position objects
  List<Position> _mapToPositions(List<dynamic> positions) {
    return positions.map((posData) {
      if (posData is Map<String, dynamic>) {
        return Position(
          title: posData['title'] as String?,
          text: posData['text'] as String?,
        );
      }
      return Position();
    }).toList();
  }

  /// Convert Firestore list to ReadyPosition objects
  List<ReadyPosition> _mapToReadyPositions(List<dynamic> readyPositions) {
    return readyPositions.map((rpData) {
      if (rpData is Map<String, dynamic>) {
        return ReadyPosition(
          title: rpData['title'] as String?,
          text: rpData['text'] as String?,
        );
      }
      return ReadyPosition();
    }).toList();
  }

  /// Convert Firestore list to RangeCommand objects
  List<RangeCommand> _mapToRangeCommands(List<dynamic> rangeCommands) {
    return rangeCommands.map((rcData) {
      if (rcData is Map<String, dynamic>) {
        return RangeCommand(
          title: rcData['title'] as String?,
          text: rcData['text'] as String?,
        );
      }
      return RangeCommand();
    }).toList();
  }

  /// Convert Firestore list to EventNotes objects
  List<EventNotes>? _mapToEventNotes(List<dynamic>? eventNotesList) {
    if (eventNotesList == null) return null;
    return eventNotesList.map((noteData) {
      if (noteData is Map<String, dynamic>) {
        return EventNotes(
          text: noteData['text'] as String? ?? '',
        );
      }
      return EventNotes(text: '');
    }).toList();
  }

  /// Convert Firestore list to Tie objects
  List<Tie>? _mapToTies(List<dynamic>? tiesList) {
    if (tiesList == null) return null;
    return tiesList.map((tieData) {
      if (tieData is Map<String, dynamic>) {
        return Tie(
          title: tieData['title'] as String?,
          text: tieData['text'] as String?,
          idx: tieData['idx'] as String?,
          idxText: tieData['idxText'] as String?,
        );
      }
      return Tie();
    }).toList();
  }

  /// Convert Firestore list to ProceduralPenalty objects
  List<ProceduralPenalty>? _mapToProceduralPenalties(List<dynamic>? penaltiesList) {
    if (penaltiesList == null) return null;
    return penaltiesList.map((ppData) {
      if (ppData is Map<String, dynamic>) {
        return ProceduralPenalty(
          title: ppData['title'] as String?,
          text: ppData['text'] as String?,
          idx: ppData['idx'] as String?,
          idxText: ppData['idxText'] as String?,
        );
      }
      return ProceduralPenalty();
    }).toList();
  }

  /// Convert Firestore list to Classification objects
  List<Classification>? _mapToClassifications(List<dynamic>? classificationsList) {
    if (classificationsList == null) return null;
    return classificationsList.map((classData) {
      if (classData is Map<String, dynamic>) {
        return Classification(
          className: classData['className'] as String? ?? '',
          min: classData['min'] as int?,
          max: classData['max'] as int?,
        );
      }
      return Classification(className: '');
    }).toList();
  }

  /// Convert Firestore map to CourseOfFire object
  CourseOfFire _mapToCourseOfFire(Map<String, dynamic>? data) {
    if (data == null) return CourseOfFire();
    return CourseOfFire(
      distance: data['distance'] as int?,
      distanceNotes: data['distanceNotes'] as String?,
      totalTime: data['totalTime'] as int?,
      timeNotes: data['timeNotes'] as String?,
      totalRounds: data['totalRounds'] as int?,
      roundsNotes: data['roundsNotes'] as String?,
      maxScore: data['maxScore'] as int?,
      maxScoreNotes: data['maxScoreNotes'] as String?,
      generalNotes: data['generalNotes'] as String?,
    );
  }

  /// Convert Firestore list to Sighters objects
  List<Sighters>? _mapToSighters(List<dynamic>? sightersList) {
    if (sightersList == null) return null;
    return sightersList.map((sighterData) {
      if (sighterData is Map<String, dynamic>) {
        return Sighters(
          text: sighterData['text'] as String? ?? '',
        );
      }
      return Sighters(text: '');
    }).toList();
  }

  /// Convert Firestore list to Practice objects
  List<Practice> _mapToPractices(List<dynamic> practices) {
    return practices.map((practiceData) {
      if (practiceData is Map<String, dynamic>) {
        return Practice(
          practiceNumber: practiceData['practiceNumber'] as int,
          practiceName: practiceData['practiceName'] as String?,
          stages: practiceData['stages'] != null
              ? _mapToStages(practiceData['stages'] as List<dynamic>)
              : [],
        );
      }
      return Practice(practiceNumber: 0, stages: []);
    }).toList();
  }

  /// Convert Firestore list to Stage objects
  List<Stage> _mapToStages(List<dynamic> stages) {
    return stages.map((stageData) {
      if (stageData is Map<String, dynamic>) {
        return Stage(
          stageNumber: stageData['stageNumber'] as int,
          distance: stageData['distance'] as int?,
          distanceText: stageData['distanceText'] as String?,
          rounds: stageData['rounds'] as int?,
          roundsText: stageData['roundsText'] as String?,
          time: stageData['time'] as double?,
          timeText: stageData['timeText'] as String?,
          notesHeader: stageData['notesHeader'] as String?,
          notes: stageData['notes'] as String?,
        );
      }
      return Stage(stageNumber: 0);
    }).toList();
  }

  /// Convert Firestore map to Notes object
  Notes? _mapToNotes(Map<String, dynamic>? data) {
    if (data == null) return null;
    return Notes(
      text: data['text'] as String?,
    );
  }

  /// Convert Firestore map to Scoring object
  Scoring? _mapToScoring(Map<String, dynamic>? data) {
    if (data == null) return null;
    return Scoring(
      text: data['text'] as String?,
    );
  }

  /// Convert Firestore map to Loading object
  Loading? _mapToLoading(Map<String, dynamic>? data) {
    if (data == null) return null;
    return Loading(
      title: data['title'] as String?,
      text: data['text'] as String?,
    );
  }

  /// Convert Firestore list to Magazine objects
  List<Magazine>? _mapToMagazines(List<dynamic>? magazineList) {
    if (magazineList == null) return null;
    return magazineList.map((magData) {
      if (magData is Map<String, dynamic>) {
        return Magazine(
          title: magData['title'] as String?,
          text: magData['text'] as String?,
        );
      }
      return Magazine();
    }).toList();
  }

  /// Convert Firestore map to Reloading object
  Reloading? _mapToReloading(Map<String, dynamic>? data) {
    if (data == null) return null;
    return Reloading(
      title: data['title'] as String?,
      text: data['text'] as String?,
    );
  }

  /// Convert Firestore map to Equipment object
  Equipment? _mapToEquipment(Map<String, dynamic>? data) {
    if (data == null) return null;
    return Equipment(
      title: data['title'] as String?,
      text: data['text'] as String?,
    );
  }

  /// Convert Firestore map to RangeEquipment object
  RangeEquipment? _mapToRangeEquipment(Map<String, dynamic>? data) {
    if (data == null) return null;
    return RangeEquipment(
      title: data['title'] as String?,
      text: data['text'] as String?,
    );
  }

  /// Convert Firestore map to ChangingPosition object
  ChangingPosition? _mapToChangingPosition(Map<String, dynamic>? data) {
    if (data == null) return null;
    return ChangingPosition(
      title: data['title'] as String?,
      text: data['text'] as String?,
    );
  }
}