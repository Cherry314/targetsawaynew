// Master lookup tables for all competition entities
// These define the actual data that IDs in EventContent reference

import 'package:targetsaway/models/hive/target.dart';
import 'package:targetsaway/models/hive/position.dart';
import 'package:targetsaway/models/hive/range_command.dart';
import 'package:targetsaway/models/hive/tie.dart';
import 'package:targetsaway/models/hive/procedural_penalty.dart';
import 'package:targetsaway/models/hive/classification.dart';
import 'package:targetsaway/models/hive/target_position.dart';
import 'package:targetsaway/models/hive/practice_stage.dart';
import 'package:targetsaway/models/hive/target_id.dart';
import 'package:targetsaway/models/hive/zone.dart';

// ============================================
// DISPLAY CONFIGURATION
// Control which fields to show for each entity type
// ============================================

/// Display configuration for entity fields
class DisplayConfig {
  // Target display options
  final bool showTargetTitle;
  final bool showTargetText;
  final bool showTargetLink;
  final bool showTargetQty;
  
  // Position display options
  final bool showPositionTitle;
  final bool showPositionText;
  
  // Practice Stage display options
  final bool showPracticeDistance;
  final bool showPracticeRounds;
  final bool showPracticeTime;
  final bool showPracticeHeader;
  final bool showPracticeNotes;
  
  // Classification display options
  final bool showClassRange;
  
  // TargetID display options
  final bool showTargetIdZones;
  final bool showTargetIdImage;

  const DisplayConfig({
    // Target defaults
    this.showTargetTitle = true,
    this.showTargetText = true,
    this.showTargetLink = false, // Hide links by default
    this.showTargetQty = true,
    
    // Position defaults
    this.showPositionTitle = true,
    this.showPositionText = true,
    
    // Practice Stage defaults
    this.showPracticeDistance = true,
    this.showPracticeRounds = true,
    this.showPracticeTime = true,
    this.showPracticeHeader = true,
    this.showPracticeNotes = false, // Can be verbose
    
    // Classification defaults
    this.showClassRange = true,
    
    // TargetID defaults
    this.showTargetIdZones = true,
    this.showTargetIdImage = false, // Hide image paths
  });

  /// Preset: Show only titles/names (minimal)
  static const DisplayConfig minimal = DisplayConfig(
    showTargetTitle: true,
    showTargetText: false,
    showTargetLink: false,
    showTargetQty: false,
    showPositionTitle: true,
    showPositionText: false,
    showPracticeHeader: true,
    showPracticeNotes: false,
    showPracticeDistance: false,
    showPracticeRounds: false,
    showPracticeTime: false,
    showClassRange: false,
    showTargetIdZones: false,
    showTargetIdImage: false,
  );

  /// Preset: Show titles and key info (compact)
  static const DisplayConfig compact = DisplayConfig(
    showTargetTitle: true,
    showTargetText: false,
    showTargetLink: false,
    showTargetQty: true,
    showPositionTitle: true,
    showPositionText: false,
    showPracticeHeader: true,
    showPracticeNotes: false,
    showPracticeDistance: true,
    showPracticeRounds: true,
    showPracticeTime: false,
    showClassRange: true,
    showTargetIdZones: false,
    showTargetIdImage: false,
  );

  /// Preset: Show everything (verbose)
  static const DisplayConfig verbose = DisplayConfig(
    showTargetTitle: true,
    showTargetText: true,
    showTargetLink: true,
    showTargetQty: true,
    showPositionTitle: true,
    showPositionText: true,
    showPracticeHeader: true,
    showPracticeNotes: true,
    showPracticeDistance: true,
    showPracticeRounds: true,
    showPracticeTime: true,
    showClassRange: true,
    showTargetIdZones: true,
    showTargetIdImage: true,
  );

  /// Preset: Default balanced view
  static const DisplayConfig standard = DisplayConfig();
}

/// Per-event display configuration (optional)
/// Use this to customize display for specific events
final Map<int, DisplayConfig> eventDisplayConfig = {
  // Example: Event 1 shows only titles and quantities
  // 1: DisplayConfig.compact,
  
  // Example: Event 2 shows everything
  // 2: DisplayConfig.verbose,
  
  // Example: Custom config for event 3
  // 3: DisplayConfig(
  //   showTargetTitle: true,
  //   showTargetText: false,
  //   showTargetQty: true,
  // ),
};

/// Get display config for an event (returns standard if not configured)
DisplayConfig getDisplayConfigForEvent(int eventNumber) {
  return eventDisplayConfig[eventNumber] ?? DisplayConfig.standard;
}

// ============================================
// TARGETS - Physical target specifications
// 
// All fields except 'title' are OPTIONAL!
// Just leave out fields you don't want to display.
//
// Examples:
//   Target(title: 'DP1')                         // Title only
//   Target(title: 'DP1', qtyNeeded: 1)          // Title + Qty
//   Target(title: 'DP1', text: 'Description')   // Title + Description
//   Target(title: 'DP1', qtyNeeded: 1, text: 'Desc') // Title + Qty + Desc
//
// ============================================
final Map<int, Target> targetTable = {
  1: Target(
    title: 'DP1',
    text: 'Decimal target for precision shooting at 25m',
    link: 'https://example.com/targets/dp1.pdf',
    qtyNeeded: 1,
  ),
  2: Target(
    title: 'DP2',
    text: 'Alternative decimal target for 25m precision',
    link: 'https://example.com/targets/dp2.pdf',
    qtyNeeded: 2,
  ),
  3: Target(
    title: 'ISSF 50m Target',
    text: 'International standard 50m rifle target',
    link: 'https://example.com/targets/issf50m.pdf',
    qtyNeeded: 1,
  ),
  4: Target(
    title: 'NRA 50m Standard',
    text: 'NRA approved 50m rifle target with 10-ring scoring',
    link: 'https://example.com/targets/nra50m.pdf',
    qtyNeeded: 1,
  ),
  5: Target(
    title: 'GRCF Target',
    text: 'Specialized target for Gallery Rifle Centrefire competition',
    link: 'https://example.com/targets/grcf.pdf',
    qtyNeeded: 1,
  ),
  6: Target(
    title: 'GRCF Alternative',
    text: 'Alternative GRCF target for varying conditions',
    link: 'https://example.com/targets/grcf-alt.pdf',
    qtyNeeded: 1,
  ),
  7: Target(
    title: 'SR-1 100yd',
    text: 'Service rifle target for 100 yard competition',
    link: 'https://example.com/targets/sr1-100.pdf',
    qtyNeeded: 1,
  ),
  8: Target(
    title: 'SR-3 Rapid Fire',
    text: 'Service rifle rapid fire target',
    link: 'https://example.com/targets/sr3-rapid.pdf',
    qtyNeeded: 2,
  ),
  9: Target(
    title: 'SR Silhouette',
    text: 'Service rifle silhouette target for various positions',
    link: 'https://example.com/targets/sr-silhouette.pdf',
    qtyNeeded: 3,
  ),
  10: Target(
    title: 'Pistol 25yd Bullseye',
    text: 'Standard bullseye pistol target for 25 yards',
    link: 'https://example.com/targets/pistol-25-bullseye.pdf',
    qtyNeeded: 1,
  ),
  11: Target(
    title: 'Pistol 50yd Precision',
    text: 'Long range pistol precision target',
    link: 'https://example.com/targets/pistol-50-precision.pdf',
    qtyNeeded: 1,
  ),
  12: Target(
    title: 'Distinguished Pistol B-8',
    text: 'NRA B-8 repair center target for distinguished matches',
    link: 'https://example.com/targets/b8-repair.pdf',
    qtyNeeded: 5,
  ),
  13: Target(
    title: 'Distinguished Pistol B-6',
    text: 'NRA B-6 target for 50 yard slow fire',
    link: 'https://example.com/targets/b6.pdf',
    qtyNeeded: 3,
  ),
  14: Target(
    title: 'Timed & Rapid Fire',
    text: 'Target for timed and rapid fire pistol stages',
    link: 'https://example.com/targets/timed-rapid.pdf',
    qtyNeeded: 6,
  ),
  15: Target(
    title: 'Chicken Silhouette 40m',
    text: 'Metallic chicken silhouette for .22 rifle',
    qtyNeeded: 10,
  ),
  16: Target(
    title: 'Pig Silhouette 60m',
    text: 'Metallic pig silhouette for .22 rifle',
    qtyNeeded: 10,
  ),
  17: Target(
    title: 'Turkey Silhouette 77m',
    text: 'Metallic turkey silhouette for .22 rifle',
    qtyNeeded: 10,
  ),
  18: Target(
    title: 'Ram Silhouette 100m',
    text: 'Metallic ram silhouette for .22 rifle',
    qtyNeeded: 10,
  ),
  19: Target(
    title: 'Half-Scale Chicken',
    text: 'Half-scale chicken silhouette for junior competition',
    qtyNeeded: 10,
  ),
  34: Target(
    title: 'Shotgun Clay',
    text: 'Standard clay pigeon for shotgun events',
    qtyNeeded: 100,
  ),
};

// ============================================
// POSITIONS - Shooting positions
// ============================================
final Map<int, Position> positionTable = {
  1: Position(
    title: 'Standing',
    text: 'Standing unsupported position. No contact with ground except feet. No artificial support.',
  ),
  2: Position(
    title: 'Kneeling',
    text: 'Kneeling position with one knee on ground. Left elbow rests on left knee (right-handed shooter).',
  ),
  3: Position(
    title: 'Prone',
    text: 'Prone position lying flat. Body extended behind rifle, both elbows on ground or mat.',
  ),
  4: Position(
    title: 'Sitting',
    text: 'Sitting position with buttocks on ground. Both elbows may rest on knees or inside of legs.',
  ),
  5: Position(
    title: 'Standing-Supported',
    text: 'Standing position with support allowed (sling, rest, or barricade contact permitted).',
  ),
};

// ============================================
// RANGE COMMANDS - Official range commands
// ============================================
final Map<int, RangeCommand> rangeCommandTable = {
  1: RangeCommand(
    title: 'Load',
    text: 'Load your firearm with the prescribed number of rounds. Keep muzzle pointed downrange.',
  ),
  2: RangeCommand(
    title: 'Ready',
    text: 'Assume shooting position. Finger off trigger until ready to fire.',
  ),
  3: RangeCommand(
    title: 'Fire',
    text: 'Commence firing when ready. Time limit begins now.',
  ),
  4: RangeCommand(
    title: 'Cease Fire',
    text: 'Stop firing immediately. Remove finger from trigger. Keep muzzle downrange.',
  ),
  5: RangeCommand(
    title: 'Make Safe',
    text: 'Unload firearm completely. Lock action open. Place on bench or mat.',
  ),
  6: RangeCommand(
    title: 'Preparation Period',
    text: 'Competitors may handle equipment and prepare. No firing permitted.',
  ),
  7: RangeCommand(
    title: 'Change Targets',
    text: 'Range officers will change targets. Remain behind firing line.',
  ),
  8: RangeCommand(
    title: 'Relay Complete',
    text: 'This relay is complete. Make firearms safe and step back from line.',
  ),
  9: RangeCommand(
    title: 'Bank Begins',
    text: 'Silhouette bank begins now. You have 2.5 minutes for 5 targets.',
  ),
  10: RangeCommand(
    title: 'Bank Ends',
    text: 'Bank time has expired. Unload and show clear.',
  ),
};

// ============================================
// TIES - Tie breaking procedures
// ============================================
final Map<int, Tie> tieTable = {
  1: Tie(
    title: 'Count-back',
    text: 'Ties are broken by counting back from the last shot. Highest final shot wins.',
  ),
  2: Tie(
    title: 'Inner Ten Count',
    text: 'Ties broken by number of inner tens (X-ring hits). Most inner tens wins.',
  ),
  3: Tie(
    title: 'Last Series',
    text: 'Compare scores from the final series only. Highest final series wins.',
  ),
  4: Tie(
    title: 'Sudden Death Shoot-off',
    text: 'Tied competitors shoot additional shots until tie is broken. One shot at a time.',
  ),
  5: Tie(
    title: 'Center Shot Measurement',
    text: 'Measure distance from center of bullseye. Closest shot to center wins.',
  ),
  6: Tie(
    title: 'Silhouette Sudden Death',
    text: 'Tied shooters continue with one animal at a time until one misses.',
  ),
};

// ============================================
// PROCEDURAL PENALTIES - Rule violations
// ============================================
final Map<int, ProceduralPenalty> proceduralPenaltyTable = {
  1: ProceduralPenalty(
    title: 'Cross-firing',
    text: 'Firing at wrong target. Penalty: Disqualification from that stage or match.',
  ),
  2: ProceduralPenalty(
    title: 'Unsafe Handling',
    text: 'Unsafe firearm handling including muzzle sweep. Penalty: Immediate disqualification from match.',
  ),
  3: ProceduralPenalty(
    title: 'Late Shot',
    text: 'Shot fired after cease fire command. Penalty: Loss of highest scoring shot in that series.',
  ),
  4: ProceduralPenalty(
    title: 'Equipment Violation',
    text: 'Using prohibited equipment or modifications. Penalty: Stage zero or match disqualification.',
  ),
  5: ProceduralPenalty(
    title: 'Position Fault',
    text: 'Illegal position or support. Penalty: 2 points per shot or stage zero if repeated.',
  ),
  6: ProceduralPenalty(
    title: 'Magazine Capacity',
    text: 'Exceeding prescribed magazine capacity. Penalty: Stage zero.',
  ),
  7: ProceduralPenalty(
    title: 'Chambered Round',
    text: 'Round chambered before "Load" command. Penalty: Warning first offense, stage zero if repeated.',
  ),
  8: ProceduralPenalty(
    title: 'Time Violation',
    text: 'Exceeding time limit for stage. Penalty: Shots fired after time expires are scored as miss.',
  ),
  9: ProceduralPenalty(
    title: 'False Start',
    text: 'Starting before command given. Penalty: Warning and restart.',
  ),
  10: ProceduralPenalty(
    title: 'Target Touch',
    text: 'Touching silhouette target before it settles. Penalty: Target scored as miss.',
  ),
  11: ProceduralPenalty(
    title: 'Position Adjustment',
    text: 'Illegal adjustment between shots (silhouette). Penalty: Bank zero.',
  ),
  12: ProceduralPenalty(
    title: 'Support Violation',
    text: 'Illegal rest or support use. Penalty: Stage zero.',
  ),
};

// ============================================
// CLASSIFICATIONS - Shooter skill levels
// ============================================
final Map<int, Classification> classificationTable = {
  1: Classification(className: 'Master', min: 95, max: 100),
  2: Classification(className: 'Expert', min: 88, max: 94),
  3: Classification(className: 'Sharpshooter', min: 80, max: 87),
  4: Classification(className: 'Marksman', min: 70, max: 79),
  5: Classification(className: 'Unclassified', min: 0, max: 69),
  6: Classification(className: 'Distinguished', min: 98, max: 100),
  7: Classification(className: 'AAA', min: 90, max: 100),
  8: Classification(className: 'AA', min: 80, max: 89),
  9: Classification(className: 'A', min: 70, max: 79),
  10: Classification(className: 'B', min: 60, max: 69),
};

// ============================================
// TARGET POSITIONS - Physical target placement
// ============================================
final Map<int, TargetPosition> targetPositionTable = {
  1: TargetPosition(
    title: '25m Center',
    text: 'Target placed at 25 meters, center lane position',
  ),
  2: TargetPosition(
    title: '25m Left',
    text: 'Target placed at 25 meters, left side position',
  ),
  3: TargetPosition(
    title: '50m Center',
    text: 'Target placed at 50 meters, center lane',
  ),
  4: TargetPosition(
    title: '50m Left',
    text: 'Target placed at 50 meters, left bank',
  ),
  5: TargetPosition(
    title: '50m Right',
    text: 'Target placed at 50 meters, right bank',
  ),
  6: TargetPosition(
    title: '100yd Center',
    text: 'Target at 100 yards, center position',
  ),
  7: TargetPosition(
    title: '100yd Position 2',
    text: 'Target at 100 yards, firing point 2',
  ),
  8: TargetPosition(
    title: '100yd Position 3',
    text: 'Target at 100 yards, firing point 3',
  ),
  9: TargetPosition(
    title: '100yd Position 4',
    text: 'Target at 100 yards, firing point 4',
  ),
  10: TargetPosition(
    title: '25yd Pistol',
    text: 'Pistol target at 25 yards',
  ),
  11: TargetPosition(
    title: '50yd Pistol',
    text: 'Pistol target at 50 yards',
  ),
  12: TargetPosition(
    title: '25yd Rapid Fire',
    text: 'Pistol rapid fire position at 25 yards',
  ),
  13: TargetPosition(
    title: '40m Chicken Bank',
    text: 'Chicken silhouettes at 40 meters',
  ),
  14: TargetPosition(
    title: '60m Pig Bank',
    text: 'Pig silhouettes at 60 meters',
  ),
  15: TargetPosition(
    title: '77m Turkey Bank',
    text: 'Turkey silhouettes at 77 meters',
  ),
  16: TargetPosition(
    title: '100m Ram Bank',
    text: 'Ram silhouettes at 100 meters',
  ),
};

// ============================================
// PRACTICE STAGES - Sighting/practice periods
// ============================================
final Map<int, PracticeStage> practiceStageTable = {
  1: PracticeStage(
    distance: 25,
    rounds: 5,
    time: 600,
    notesHeader: 'Sighters - 25m',
    notes: '5 sighting shots allowed at 25 meters. Adjustments permitted between shots. 10 minutes total.',
  ),
  2: PracticeStage(
    distance: 25,
    rounds: 10,
    time: 900,
    notesHeader: 'Practice 1 - 25m',
    notes: 'First practice stage, 10 shots for record at 25m. 15 minutes.',
  ),
  3: PracticeStage(
    distance: 25,
    rounds: 10,
    time: 900,
    notesHeader: 'Practice 2 - 25m',
    notes: 'Second practice stage, 10 shots for record at 25m. 15 minutes.',
  ),
  4: PracticeStage(
    distance: 50,
    rounds: 5,
    time: 900,
    notesHeader: 'Sighters - 50m',
    notes: '5 convertible sighting shots at 50m. May be converted to record shots. 15 minutes.',
  ),
  5: PracticeStage(
    distance: 50,
    rounds: 9,
    time: 900,
    notesHeader: 'Series 1 - 50m',
    notes: 'First series for record, 9 shots at 50m prone. 15 minutes.',
  ),
  6: PracticeStage(
    distance: 50,
    rounds: 9,
    time: 900,
    notesHeader: 'Series 2 - 50m',
    notes: 'Second series for record, 9 shots at 50m prone. 15 minutes.',
  ),
  7: PracticeStage(
    distance: 100,
    rounds: 2,
    time: 300,
    notesHeader: 'Sighters - 100yd Standing',
    notes: '2 sighting shots standing at 100 yards. 5 minutes.',
  ),
  8: PracticeStage(
    distance: 100,
    rounds: 10,
    time: 600,
    notesHeader: 'Sitting Rapid - 100yd',
    notes: 'Rapid fire sitting, 10 shots in 60 seconds from standing start. Two 5-shot strings.',
  ),
  9: PracticeStage(
    distance: 100,
    rounds: 10,
    time: 600,
    notesHeader: 'Prone Rapid - 100yd',
    notes: 'Rapid fire prone, 10 shots in 70 seconds from standing start. Two 5-shot strings.',
  ),
  10: PracticeStage(
    distance: 100,
    rounds: 20,
    time: 1200,
    notesHeader: 'Slow Fire Prone - 100yd',
    notes: 'Slow fire prone, 20 shots for record. 20 minutes.',
  ),
  11: PracticeStage(
    distance: 25,
    rounds: 5,
    time: 600,
    notesHeader: 'Pistol Sighters',
    notes: 'Pistol sighting shots at 25 yards. 10 minutes.',
  ),
  12: PracticeStage(
    distance: 25,
    rounds: 10,
    time: 900,
    notesHeader: 'Pistol Timed Fire',
    notes: 'Timed fire, 2 strings of 5 shots. 20 seconds per string.',
  ),
  13: PracticeStage(
    distance: 25,
    rounds: 10,
    time: 600,
    notesHeader: 'Pistol Rapid Fire',
    notes: 'Rapid fire, 2 strings of 5 shots. 10 seconds per string.',
  ),
  14: PracticeStage(
    distance: 40,
    rounds: 2,
    time: 300,
    notesHeader: 'Silhouette Practice - Chickens',
    notes: 'Practice shots at chicken bank. Unlimited sighters before match.',
  ),
  15: PracticeStage(
    distance: 100,
    rounds: 2,
    time: 300,
    notesHeader: 'Silhouette Practice - Rams',
    notes: 'Practice shots at ram bank. Unlimited sighters before match.',
  ),
};

// ============================================
// TARGET IDs - Target identification systems
// ============================================
final Map<int, TargetID> targetIdTable = {
  1: TargetID(
    title: 'Standard Ring System',
    imageLocation: 'assets/targets/standard_rings.png',
    zones: [
      Zone(text: '10-ring (Inner 10)', size: '10.4mm'),
      Zone(text: '10-ring (Outer 10)', size: '26.4mm'),
      Zone(text: '9-ring', size: '46.8mm'),
      Zone(text: '8-ring', size: '67.2mm'),
      Zone(text: '7-ring', size: '87.6mm'),
    ],
  ),
  2: TargetID(
    title: 'Decimal Scoring',
    imageLocation: 'assets/targets/decimal_system.png',
    zones: [
      Zone(text: 'X-ring (10.9)', size: '5mm'),
      Zone(text: '10-ring', size: '20mm'),
      Zone(text: '9-ring', size: '40mm'),
      Zone(text: '8-ring', size: '60mm'),
    ],
  ),
  3: TargetID(
    title: 'ISSF 50m Rings',
    imageLocation: 'assets/targets/issf_50m.png',
    zones: [
      Zone(text: 'Inner 10', size: '10.4mm'),
      Zone(text: '10-ring', size: '26.4mm'),
      Zone(text: '9-ring', size: '46.8mm'),
      Zone(text: '8-ring', size: '67.2mm'),
    ],
  ),
  4: TargetID(
    title: 'Service Rifle Scoring',
    imageLocation: 'assets/targets/service_rifle.png',
    zones: [
      Zone(text: 'X-ring', size: '3 inches'),
      Zone(text: '10-ring', size: '7 inches'),
      Zone(text: '9-ring', size: '13 inches'),
      Zone(text: '8-ring', size: '19 inches'),
    ],
  ),
  5: TargetID(
    title: 'Pistol 25yd Rings',
    imageLocation: 'assets/targets/pistol_25yd.png',
    zones: [
      Zone(text: 'X-ring', size: '1.695 inches'),
      Zone(text: '10-ring', size: '3.36 inches'),
      Zone(text: '9-ring', size: '5.54 inches'),
      Zone(text: '8-ring', size: '7.72 inches'),
    ],
  ),
  6: TargetID(
    title: 'Rapid Fire Zones',
    imageLocation: 'assets/targets/rapid_fire.png',
    zones: [
      Zone(text: 'Center X', size: '2 inches'),
      Zone(text: '10-ring', size: '8 inches'),
      Zone(text: '9-ring', size: '14 inches'),
    ],
  ),
  7: TargetID(
    title: 'Long Range 100yd',
    imageLocation: 'assets/targets/lr_100yd.png',
    zones: [
      Zone(text: 'V-Bull', size: '5 inches'),
      Zone(text: '5-ring', size: '12 inches'),
      Zone(text: '4-ring', size: '24 inches'),
    ],
  ),
  8: TargetID(
    title: 'Silhouette Vital Zones',
    imageLocation: 'assets/targets/silhouette.png',
    zones: [
      Zone(text: 'Full knockdown required', size: 'Varies by animal'),
    ],
  ),
  9: TargetID(
    title: 'Distinguished Pistol B-8',
    imageLocation: 'assets/targets/b8_repair.png',
    zones: [
      Zone(text: 'X-ring', size: '1.695 inches'),
      Zone(text: '10-ring', size: '3.36 inches'),
      Zone(text: '9-ring', size: '5.54 inches'),
    ],
  ),
  10: TargetID(
    title: 'Distinguished Pistol B-6',
    imageLocation: 'assets/targets/b6.png',
    zones: [
      Zone(text: 'X-ring', size: '3 inches'),
      Zone(text: '10-ring', size: '7 inches'),
      Zone(text: '9-ring', size: '13 inches'),
    ],
  ),
  11: TargetID(
    title: 'Timed/Rapid Scoring',
    imageLocation: 'assets/targets/timed_rapid.png',
    zones: [
      Zone(text: 'X-ring', size: '1.695 inches'),
      Zone(text: '10-ring', size: '3.36 inches'),
    ],
  ),
  12: TargetID(
    title: 'Chicken Silhouette',
    imageLocation: 'assets/targets/chicken.png',
    zones: [
      Zone(text: 'Full target', size: '1/5 scale IHMSA'),
    ],
  ),
  13: TargetID(
    title: 'Pig Silhouette',
    imageLocation: 'assets/targets/pig.png',
    zones: [
      Zone(text: 'Full target', size: '1/5 scale IHMSA'),
    ],
  ),
  14: TargetID(
    title: 'Turkey Silhouette',
    imageLocation: 'assets/targets/turkey.png',
    zones: [
      Zone(text: 'Full target', size: '1/5 scale IHMSA'),
    ],
  ),
  15: TargetID(
    title: 'Ram Silhouette',
    imageLocation: 'assets/targets/ram.png',
    zones: [
      Zone(text: 'Full target', size: '1/5 scale IHMSA'),
    ],
  ),
};

// Helper function to get entity by ID
T? getEntityById<T>(Map<int, T> table, int id) {
  return table[id];
}

// Helper function to get multiple entities by IDs
List<T> getEntitiesByIds<T>(Map<int, T> table, List<int> ids) {
  return ids.map((id) => table[id]).whereType<T>().toList();
}
