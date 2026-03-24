// lib/screens/enter_score_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../models/score_entry.dart';
import '../models/firearm_entry.dart';
import '../models/rounds_counter_entry.dart';
import '../models/hive/event.dart';
import '../models/hive/firearm.dart';
import '../models/hive/practice.dart';
import '../data/dropdown_values.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';
import '../services/calendar_score_service.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';
import 'methods/notes_dialog.dart';
import 'methods/practice_selection_dialog.dart';
import 'methods/firearm_selection_dialog.dart';
import 'methods/caliber_selection_dialog.dart';
import 'methods/event_details_dialog.dart';
import 'methods/score_calculator_dialog.dart';
import 'event_scoring_screen.dart';

class EnterScoreScreen extends StatefulWidget {
  final ScoreEntry? editEntry;
  final bool openedFromCalendar;
  final bool scoringMode;
  final bool eventScoringMode;
  final DateTime? initialDate;
  final String? initialPractice;
  final String? initialCaliber;
  final String? initialFirearmId;
  final String? initialFirearm;

  const EnterScoreScreen({
    super.key,
    this.editEntry,
    this.openedFromCalendar = false,
    this.scoringMode = false,
    this.eventScoringMode = false,
    this.initialDate,
    this.initialPractice,
    this.initialCaliber,
    this.initialFirearmId,
    this.initialFirearm,
  });

  @override
  EnterScoreScreenState createState() => EnterScoreScreenState();
}

class EnterScoreScreenState extends State<EnterScoreScreen> {
  final scoreController = TextEditingController();
  final xController = TextEditingController();
  final firearmController = TextEditingController();
  final notesController = TextEditingController();
  final compIdController = TextEditingController();
  final compResultController = TextEditingController();

  String? selectedPractice;
  String? previousPractice; // Track previous selection for reverting
  String? selectedCaliber;
  String? selectedFirearmId;

  // Personal firearm selection
  String? selectedPersonalFirearmId; // ID of selected personal firearm from FirearmEntry
  bool get _showManualFirearmFields => selectedPersonalFirearmId == null || selectedPersonalFirearmId == 'manual';

  File? targetImage;
  File? thumbnailImage;

  DateTime selectedDate = DateTime.now();

  // Score breakdown storage (from calculator)
  Map<int, int>? _scoreBreakdown;

  // Event scoring per-target storage
  final List<int?> _targetScores = [];
  final List<int?> _targetXCounts = [];
  final List<Map<int, int>?> _targetBreakdowns = [];
  final List<int?> _targetBasicScores = [];
  final List<File?> _targetImages = [];
  final List<File?> _targetThumbnails = [];

  // Cache the practice items at state level to prevent recreation on every build
  List<DropdownMenuItem<String>> _cachedPracticeItems = [];
  String _cachedPracticeListHash = '';

  @override
  void initState() {
    super.initState();
    _initializeScreen();

    firearmController.addListener(() => setState(() {}));
    notesController.addListener(() => setState(() {}));
    compIdController.addListener(() => setState(() {}));
    compResultController.addListener(() => setState(() {}));
  }

  Future<void> _initializeScreen() async {
    await _loadLastSelections();

    if (widget.scoringMode) {
      setState(() {
        if (widget.initialDate != null) selectedDate = widget.initialDate!;
        if (widget.initialPractice != null && widget.initialPractice!.isNotEmpty) {
          selectedPractice = widget.initialPractice;
        }
        if (widget.initialCaliber != null && widget.initialCaliber!.isNotEmpty) {
          selectedCaliber = widget.initialCaliber;
        }
        if (widget.initialFirearmId != null && widget.initialFirearmId!.isNotEmpty) {
          selectedFirearmId = widget.initialFirearmId;
        }
        if (widget.initialFirearm != null && widget.initialFirearm!.isNotEmpty) {
          firearmController.text = widget.initialFirearm!;
        }
      });
    }

    if (widget.editEntry != null && !widget.openedFromCalendar) {
      // Only populate fields if it's a real edit entry (not from calendar)
      _populateEditFields();
      selectedDate = widget.editEntry!.date;
    } else if (widget.editEntry != null && widget.openedFromCalendar) {
      // From calendar: just set the date, keep last selections
      setState(() {
        selectedDate = widget.editEntry!.date;
      });
    }
  }

  void _populateEditFields() {
    final entry = widget.editEntry!;
    scoreController.text = entry.score.toString();
    xController.text = entry.x?.toString() ?? '';
    firearmController.text = entry.firearm ?? '';
    notesController.text = entry.notes ?? '';
    compIdController.text = entry.compId ?? '';
    compResultController.text = entry.compResult ?? '';

    setState(() {
      // Validate that the practice exists in the dropdown list
      final currentPractices = DropdownValues.practices;
      if (!currentPractices.contains(entry.practice) && entry.practice.isNotEmpty) {
        // If not in favorites, add it temporarily
        final practicesWithoutEmpty = currentPractices
            .where((p) => p.isNotEmpty)
            .toList();
        DropdownValues.practices = [entry.practice, ...practicesWithoutEmpty];
      }
      selectedPractice = entry.practice;

      selectedCaliber = entry.caliber;
      selectedFirearmId = entry.firearmId;

      targetImage =
      entry.targetFilePath != null ? File(entry.targetFilePath!) : null;
      thumbnailImage =
      entry.thumbnailFilePath != null ? File(entry.thumbnailFilePath!) : null;
    });
  }

  Future<void> _loadLastSelections() async {
    final prefs = await SharedPreferences.getInstance();

    // Load favorite practices from SharedPreferences
    final favoritePractices = prefs.getStringList('favoritePractices');
    if (favoritePractices != null && favoritePractices.isNotEmpty) {
      // Clean and filter the data (remove 'All' if it exists)
      final cleanedPractices = favoritePractices
          .where((p) => p != 'All')
          .toList();
      // Save back the cleaned data
      await prefs.setStringList('favoritePractices', cleanedPractices);
      // The setter will automatically filter out 'All' and add empty string at the top
      DropdownValues.practices = cleanedPractices;
    }

// Load favorite calibers from SharedPreferences
    final favoriteCalibers = prefs.getStringList('favoriteCalibers');
    if (favoriteCalibers != null && favoriteCalibers.isNotEmpty) {
      DropdownValues.calibers = favoriteCalibers;
    }

// Load favorite firearm IDs from SharedPreferences
    final favoriteFirearmIds = prefs.getStringList('favoriteFirearmIds');
    if (favoriteFirearmIds != null && favoriteFirearmIds.isNotEmpty) {
      DropdownValues.favoriteFirearmIds = favoriteFirearmIds
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toList();
    }

    setState(() {
      // Get the last selected practice
      // Only use editEntry values if NOT from calendar and values are not empty
      final lastPractice = (widget.editEntry?.practice != null &&
          widget.editEntry!.practice.isNotEmpty &&
          !widget.openedFromCalendar)
          ? widget.editEntry!.practice
          : prefs.getString('lastPractice');

      final practicesList = DropdownValues.practices;
      // Ensure the selected practice exists in the dropdown list
      if (lastPractice != null && practicesList.contains(lastPractice)) {
        selectedPractice = lastPractice;
      } else {
        // Select first item in list (empty string if no favorites, or first favorite)
        selectedPractice = practicesList.first;
      }

      // Only use editEntry caliber if NOT from calendar and not empty
      final lastCaliber = (widget.editEntry?.caliber != null &&
          widget.editEntry!.caliber.isNotEmpty &&
          !widget.openedFromCalendar)
          ? widget.editEntry!.caliber
          : prefs.getString('lastCaliber');

      final calibersList = DropdownValues.calibers;
      if (lastCaliber != null && calibersList.contains(lastCaliber)) {
        selectedCaliber = lastCaliber;
      } else {
        // Select first item in list (empty string if no favorites, or first favorite)
        selectedCaliber = calibersList.first;
      }

      // Get the last firearm ID
      // Only use editEntry firearmId if NOT from calendar and not empty
      final lastFirearmId = (widget.editEntry?.firearmId != null &&
          widget.editEntry!.firearmId.isNotEmpty &&
          !widget.openedFromCalendar)
          ? widget.editEntry!.firearmId
          : prefs.getString('lastFirearmId');

      final firearmIdsList = DropdownValues.firearmIds;
      if (lastFirearmId != null && firearmIdsList.contains(lastFirearmId)) {
        selectedFirearmId = lastFirearmId;
      } else {
        // Select first item in list (empty string if no favorites, or first favorite)
        selectedFirearmId = firearmIdsList.first;
      }

      // Load last firearm name if not from calendar or if editEntry doesn't have it
      if (!widget.openedFromCalendar ||
          widget.editEntry?.firearm == null ||
          widget.editEntry!.firearm!.isEmpty) {
        final lastFirearm = prefs.getString('lastFirearm');
        if (lastFirearm != null) {
          firearmController.text = lastFirearm;
        }
      }
    });
  }

  Future<void> _saveSelection(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _resetFormForNextEntry() {
    setState(() {
      // Clear the score field
      scoreController.clear();
      xController.clear();

      // Clear optional fields
      firearmController.clear();
      notesController.clear();
      compIdController.clear();
      compResultController.clear();

      // Clear images
      targetImage = null;
      thumbnailImage = null;
      
      // Clear score breakdown
      _scoreBreakdown = null;
      _targetScores.clear();
      _targetXCounts.clear();
      _targetBreakdowns.clear();
      _targetBasicScores.clear();
      _targetImages.clear();
      _targetThumbnails.clear();

      // Reset date to today
      selectedDate = DateTime.now();

      // Keep the last selected practice, caliber, and firearm ID
      // (They're already in state from the last save)
    });
  }

  Future<File> _generateThumbnail(File originalImage) async {
    final bytes = await originalImage.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final thumbnail = img.copyResize(image, width: 150);

    final thumbPath = originalImage.path.replaceFirst('.jpg', '_thumb.jpg');
    final thumbFile = File(thumbPath);

    await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 70));
    return thumbFile;
  }

  Future<void> _pickImage() async {
    final imageQualityProvider = Provider.of<ImageQualityProvider>(
        context, listen: false);
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQualityProvider.qualityPercentage
    );

    if (pickedFile != null) {
      final fullFile = File(pickedFile.path);
      final thumbFile = await _generateThumbnail(fullFile);

      setState(() {
        targetImage = fullFile;
        thumbnailImage = thumbFile;
      });
    }
  }

  void _ensureTargetSlots(int count) {
    while (_targetScores.length < count) {
      _targetScores.add(null);
      _targetXCounts.add(null);
      _targetBreakdowns.add(null);
      _targetBasicScores.add(null);
      _targetImages.add(null);
      _targetThumbnails.add(null);
    }

    if (_targetScores.length > count) {
      _targetScores.removeRange(count, _targetScores.length);
      _targetXCounts.removeRange(count, _targetXCounts.length);
      _targetBreakdowns.removeRange(count, _targetBreakdowns.length);
      _targetBasicScores.removeRange(count, _targetBasicScores.length);
      _targetImages.removeRange(count, _targetImages.length);
      _targetThumbnails.removeRange(count, _targetThumbnails.length);
    }
  }

  Future<void> _pickImageForTarget(int index) async {
    final imageQualityProvider = Provider.of<ImageQualityProvider>(
        context, listen: false);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQualityProvider.qualityPercentage,
    );

    if (pickedFile != null) {
      final fullFile = File(pickedFile.path);
      final thumbFile = await _generateThumbnail(fullFile);

      setState(() {
        _targetImages[index] = fullFile;
        _targetThumbnails[index] = thumbFile;
      });
    }
  }

  Future<void> _openScoreCalculatorForTarget(int index) async {
    final calcTotalRounds = _getTotalRoundsForTarget(index);
    final result = await showScoreCalculatorDialog(
      context: context,
      totalRounds: calcTotalRounds,
      selectedPractice: selectedPractice,
      selectedFirearmId: selectedFirearmId,
    );

    if (result != null) {
      setState(() {
        _targetScores[index] = result.score;
        _targetXCounts[index] = result.xCount > 0 ? result.xCount : 0;
        _targetBreakdowns[index] = result.scoreCounts;
        _targetBasicScores[index] = null;
      });
    }
  }

  Future<void> _openBasicScoreForTarget(int index, Color primaryColor) async {
    final targetRounds = _getTotalRoundsForTarget(index);
    final maxScoreForTarget = targetRounds != null ? targetRounds * 10 : null;

    final result = await showDialog<Map<String, String>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _BasicScoreDialogContent(
          primaryColor: primaryColor,
          initialScore: _targetScores[index]?.toString() ?? '',
          initialXCount: _targetXCounts[index]?.toString() ?? '',
          maxScore: maxScoreForTarget,
        );
      },
    );

    if (result != null) {
      setState(() {
        final parsedScore = int.tryParse(result['score'] ?? '');
        final parsedX = int.tryParse(result['xCount'] ?? '');
        _targetScores[index] = parsedScore;
        _targetXCounts[index] = parsedX;
        _targetBreakdowns[index] = null;
        _targetBasicScores[index] = parsedScore;
      });
    }
  }

  void _confirmSaveEntry() async {
    final isEventScoring = widget.eventScoringMode;

    if (isEventScoring) {
      final expectedTargets = _getRequiredTargetCountForSelectedEvent() ?? 1;
      _ensureTargetSlots(expectedTargets);
      final hasMissingTargetScores = _targetScores.take(expectedTargets).any((score) => score == null);
      if (hasMissingTargetScores) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a score for each target.')),
        );
        return;
      }
    } else {
      final scoreValid = scoreController.text.isNotEmpty &&
          int.tryParse(scoreController.text) != null;

      if (!scoreValid) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a valid score")));
        return;
      }
    }

    // Validate required fields are set
    if (selectedCaliber == null || selectedCaliber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a Caliber")));
      return;
    }
    if (selectedFirearmId == null || selectedFirearmId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a Firearm ID")));
      return;
    }

    // Check if rounds counter is enabled
    final roundsCounterEnabled = Provider.of<RoundsCounterProvider>(context, listen: false).enabled;

    // Calculate rounds from score breakdown
    int? roundsUsed;
    if (isEventScoring) {
      int totalRoundsUsed = 0;
      for (final breakdown in _targetBreakdowns) {
        if (breakdown == null) continue;
        totalRoundsUsed += ((breakdown[10] ?? 0) +
            (breakdown[9] ?? 0) +
            (breakdown[8] ?? 0) +
            (breakdown[7] ?? 0) +
            (breakdown[6] ?? 0) +
            (breakdown[5] ?? 0) +
            (breakdown[4] ?? 0) +
            (breakdown[3] ?? 0) +
            (breakdown[2] ?? 0) +
            (breakdown[1] ?? 0) +
            (breakdown[0] ?? 0));
      }
      roundsUsed = totalRoundsUsed > 0 ? totalRoundsUsed : null;
    } else if (_scoreBreakdown != null) {
      roundsUsed = (_scoreBreakdown![10] ?? 0) +
          (_scoreBreakdown![9] ?? 0) +
          (_scoreBreakdown![8] ?? 0) +
          (_scoreBreakdown![7] ?? 0) +
          (_scoreBreakdown![6] ?? 0) +
          (_scoreBreakdown![5] ?? 0) +
          (_scoreBreakdown![4] ?? 0) +
          (_scoreBreakdown![3] ?? 0) +
          (_scoreBreakdown![2] ?? 0) +
          (_scoreBreakdown![1] ?? 0) +
          (_scoreBreakdown![0] ?? 0);
    }

    // Controllers for rounds counter dialog
    final sightersController = TextEditingController();
    final roundsNotesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Confirm Save"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.openedFromCalendar
                        ? "Do you want to save this entry and return to the Calendar?"
                        : "Do you want to save this entry?",
                  ),
                  if (roundsCounterEnabled) ...[
                    const SizedBox(height: 20),
                    if (roundsUsed != null) ...[
                      Text(
                        'Rounds to be recorded: $roundsUsed',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Were any Sighters used?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sightersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sighters',
                        hintText: 'Enter number of sighters',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Any notes regarding Rounds used?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roundsNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Enter any notes about rounds',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final box = Hive.box<ScoreEntry>('scores');
                  final compIsTrue = compIdController.text.isNotEmpty ||
                      compResultController.text.isNotEmpty;

                  final targetScoreTotal = isEventScoring
                      ? _targetScores.whereType<int>().fold<int>(0, (sum, score) => sum + score)
                      : int.parse(scoreController.text);

                  final targetXTotal = isEventScoring
                      ? _targetXCounts.whereType<int>().fold<int>(0, (sum, x) => sum + x)
                      : (xController.text.isNotEmpty ? int.tryParse(xController.text) : null);

                  final eventTargetCount = _getRequiredTargetCountForSelectedEvent() ?? 1;

                  final newEntry = ScoreEntry(
                    id: widget.editEntry?.id ??
                        DateTime
                            .now()
                            .millisecondsSinceEpoch
                            .toString(),
                    date: selectedDate,
                    score: targetScoreTotal,
                    practice: selectedPractice!,
                    caliber: selectedCaliber!,
                    firearmId: selectedFirearmId ?? '',
                    firearm: firearmController.text,
                    notes: isEventScoring ? null : notesController.text,
                    comp: compIsTrue,
                    compId: compIdController.text,
                    compResult: compResultController.text,
                    targetFilePath: isEventScoring ? null : targetImage?.path,
                    thumbnailFilePath: isEventScoring ? null : thumbnailImage?.path,
                    targetCaptured: isEventScoring ? _targetImages.any((f) => f != null) : targetImage != null,
                    x: targetXTotal,
                    // Score breakdown from calculator (if available)
                    scoreX: isEventScoring
                        ? null
                        : (_scoreBreakdown != null && xController.text.isNotEmpty
                            ? int.tryParse(xController.text)
                            : null),
                    score10: isEventScoring ? null : _scoreBreakdown?[10],
                    score9: isEventScoring ? null : _scoreBreakdown?[9],
                    score8: isEventScoring ? null : _scoreBreakdown?[8],
                    score7: isEventScoring ? null : _scoreBreakdown?[7],
                    score6: isEventScoring ? null : _scoreBreakdown?[6],
                    score5: isEventScoring ? null : _scoreBreakdown?[5],
                    score4: isEventScoring ? null : _scoreBreakdown?[4],
                    score3: isEventScoring ? null : _scoreBreakdown?[3],
                    score2: isEventScoring ? null : _scoreBreakdown?[2],
                    score1: isEventScoring ? null : _scoreBreakdown?[1],
                    score0: isEventScoring ? null : _scoreBreakdown?[0],
                    scoreBasic: isEventScoring
                        ? null
                        : (_scoreBreakdown == null ? int.tryParse(scoreController.text) : null),
                    targetFilePaths: isEventScoring
                        ? List<String>.generate(eventTargetCount, (i) => _targetImages[i]?.path ?? '')
                        : (targetImage?.path != null ? [targetImage!.path] : null),
                    thumbnailFilePaths: isEventScoring
                        ? List<String>.generate(eventTargetCount, (i) => _targetThumbnails[i]?.path ?? '')
                        : (thumbnailImage?.path != null ? [thumbnailImage!.path] : null),
                    targetsCaptured: isEventScoring
                        ? List<bool>.generate(eventTargetCount, (i) => _targetImages[i] != null)
                        : [targetImage != null],
                    xs: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetXCounts[i] ?? 0)
                        : (xController.text.isNotEmpty ? [int.tryParse(xController.text) ?? 0] : null),
                    scoreXs: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetXCounts[i] ?? 0)
                        : (_scoreBreakdown != null && xController.text.isNotEmpty
                            ? [int.tryParse(xController.text) ?? 0]
                            : null),
                    score10s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[10] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![10] ?? 0] : null),
                    score9s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[9] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![9] ?? 0] : null),
                    score8s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[8] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![8] ?? 0] : null),
                    score7s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[7] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![7] ?? 0] : null),
                    score6s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[6] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![6] ?? 0] : null),
                    score5s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[5] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![5] ?? 0] : null),
                    score4s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[4] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![4] ?? 0] : null),
                    score3s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[3] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![3] ?? 0] : null),
                    score2s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[2] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![2] ?? 0] : null),
                    score1s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[1] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![1] ?? 0] : null),
                    score0s: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBreakdowns[i]?[0] ?? 0)
                        : (_scoreBreakdown != null ? [_scoreBreakdown![0] ?? 0] : null),
                    scoreBasics: isEventScoring
                        ? List<int>.generate(eventTargetCount, (i) => _targetBasicScores[i] ?? 0)
                        : [(_scoreBreakdown == null ? int.tryParse(scoreController.text) ?? 0 : 0)],
                  );

                  await box.put(newEntry.id, newEntry);

                  // Create rounds counter entries if enabled
                  if (roundsCounterEnabled && roundsUsed != null && roundsUsed > 0) {
                    final roundsBox = Hive.box<RoundsCounterEntry>('rounds_counter');

                    // Create entry for practice rounds
                    final practiceEntry = RoundsCounterEntry(
                      date: selectedDate,
                      rounds: roundsUsed,
                      reason: 'Practice',
                      notes: roundsNotesController.text.isNotEmpty
                          ? roundsNotesController.text
                          : null,
                      event: selectedPractice?.isNotEmpty == true ? selectedPractice : null,
                    );
                    await roundsBox.add(practiceEntry);

                    // Create entry for sighters if any
                    final sightersCount = int.tryParse(sightersController.text) ?? 0;
                    if (sightersCount > 0) {
                      final sightersEntry = RoundsCounterEntry(
                        date: selectedDate,
                        rounds: sightersCount,
                        reason: 'Sighters',
                        notes: null,
                        event: selectedPractice?.isNotEmpty == true ? selectedPractice : null,
                      );
                      await roundsBox.add(sightersEntry);
                    }
                  }

                  // Save the selections for next time
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('lastPractice', selectedPractice!);
                  await prefs.setString('lastCaliber', selectedCaliber!);
                  await prefs.setString('lastFirearmId', selectedFirearmId!);
                  if (firearmController.text.isNotEmpty) {
                    await prefs.setString('lastFirearm', firearmController.text);
                  }

                  // Create calendar entry for this score
                  await CalendarScoreService().createOrUpdateScoreAppointment(
                      newEntry);

                  if (!context.mounted) return;
                  Navigator.pop(context); // close dialog

                  if (widget.openedFromCalendar) {
                    if (!context.mounted) return;
                    // Return to calendar screen
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/calendar', (route) => false);
                  } else {
                    // Clear form and stay on screen for next entry
                    _resetFormForNextEntry();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Score saved! Ready for next entry.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text("Confirm Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Color iconColor(bool active) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return active ? themeProvider.primaryColor : Colors.grey;
  }

  Widget _buildSectionCard({
    required Widget child,
    required BuildContext context,
  }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  /// Check if firearm is eligible for a given practice
  bool _isFirearmEligibleForPractice(String practiceOrEvent, String firearmCode) {
    // Freestyle allows any firearm
    if (practiceOrEvent == DropdownValues.freestyle) {
      return true;
    }
    
    // If either is empty, no validation needed
    if (practiceOrEvent.isEmpty || firearmCode.isEmpty) {
      return true;
    }

    try {
      // Check if events box is open
      if (!Hive.isBoxOpen('events')) {
        return true; // Allow if events not loaded
      }
      
      final eventBox = Hive.box<Event>('events');
      
      // Find the event by matching the practice name to event name
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == practiceOrEvent) {
          matchedEvent = event;
          break;
        }
      }
      
      if (matchedEvent == null) {
        return true; // Allow if event not found
      }

      // Get the firearm ID from the code
      final firearmId = DropdownValues.getFirearmIdByCode(firearmCode);
      if (firearmId == null) {
        return true; // Allow if firearm ID not found
      }

      // Check if the firearm ID is in the applicable list
      final isEligible = matchedEvent.applicableFirearmIds.contains(firearmId);

      return isEligible;
    } catch (e) {
      return true; // Allow on error
    }
  }

  List<int>? _getPerTargetRoundsForSelectedEvent() {
    if (selectedPractice == DropdownValues.freestyle) {
      return null;
    }

    if (selectedPractice == null || selectedPractice!.isEmpty ||
        selectedFirearmId == null || selectedFirearmId!.isEmpty) {
      return null;
    }

    try {
      if (!Hive.isBoxOpen('events')) {
        return null;
      }

      final eventBox = Hive.box<Event>('events');
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == selectedPractice) {
          matchedEvent = event;
          break;
        }
      }
      if (matchedEvent == null) return null;

      final firearmId = DropdownValues.getFirearmIdByCode(selectedFirearmId!);
      if (firearmId == null) return null;

      final firearm = Firearm(
        id: firearmId,
        code: selectedFirearmId!,
        gunType: '',
      );

      final content = matchedEvent.getContentForFirearm(firearm);
      final mode = matchedEvent.scoreChangeTrigger.mode;
      final eventTotalRounds = content.courseOfFire.totalRounds ?? 0;

      if (mode == 0) {
        return [eventTotalRounds];
      }

      final practices = [...content.practices]
        ..sort((a, b) => a.practiceNumber.compareTo(b.practiceNumber));

      int practiceRounds(Practice practice) {
        int total = 0;
        for (final stage in practice.stages) {
          total += (stage.rounds ?? 0);
        }
        return total;
      }

      if (mode == 1) {
        if (practices.isEmpty) return [eventTotalRounds];
        return practices.map(practiceRounds).toList();
      }

      if (mode == 2) {
        final flattenedStages = <Map<String, int>>[];
        for (final practice in practices) {
          final stages = [...practice.stages]
            ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
          for (final stage in stages) {
            flattenedStages.add({
              'practice': practice.practiceNumber,
              'stage': stage.stageNumber,
              'rounds': stage.rounds ?? 0,
            });
          }
        }

        if (flattenedStages.isEmpty) {
          return [eventTotalRounds];
        }

        final checkpointPositions = <int>{};
        for (final checkpoint in matchedEvent.scoreChangeTrigger.checkpoints) {
          int index = -1;
          if (checkpoint.stageNumber != null) {
            index = flattenedStages.indexWhere(
              (s) => s['practice'] == checkpoint.practiceNumber && s['stage'] == checkpoint.stageNumber,
            );
          } else {
            for (int i = flattenedStages.length - 1; i >= 0; i--) {
              if (flattenedStages[i]['practice'] == checkpoint.practiceNumber) {
                index = i;
                break;
              }
            }
          }

          if (index >= 0) {
            checkpointPositions.add(index);
          }
        }

        final sortedPositions = checkpointPositions.toList()..sort();

        if (sortedPositions.isEmpty) {
          final total = flattenedStages.fold<int>(0, (sum, s) => sum + (s['rounds'] ?? 0));
          return [total];
        }

        final targetRounds = <int>[];
        int start = 0;

        for (final end in sortedPositions) {
          if (end < start) continue;
          int segmentTotal = 0;
          for (int i = start; i <= end && i < flattenedStages.length; i++) {
            segmentTotal += flattenedStages[i]['rounds'] ?? 0;
          }
          targetRounds.add(segmentTotal);
          start = end + 1;
        }

        if (start < flattenedStages.length) {
          int tailTotal = 0;
          for (int i = start; i < flattenedStages.length; i++) {
            tailTotal += flattenedStages[i]['rounds'] ?? 0;
          }
          targetRounds.add(tailTotal);
        }

        return targetRounds.isEmpty ? [eventTotalRounds] : targetRounds;
      }

      return [eventTotalRounds];
    } catch (e) {
      return null;
    }
  }

  int? _getTotalRoundsForTarget(int targetIndex) {
    final perTargetRounds = _getPerTargetRoundsForSelectedEvent();
    if (perTargetRounds == null || perTargetRounds.isEmpty) {
      return null;
    }

    if (targetIndex < perTargetRounds.length) {
      return perTargetRounds[targetIndex];
    }

    return perTargetRounds.last;
  }

/// Get the max score for the selected event/practice and firearm
  int? _getMaxScoreForSelectedEvent() {
    // Return null if Freestyle is selected (no max score for freestyle)
    if (selectedPractice == DropdownValues.freestyle) {
      return null;
    }
    
    // Return null if either practice or firearmId not selected
    if (selectedPractice == null || selectedPractice!.isEmpty ||
        selectedFirearmId == null || selectedFirearmId!.isEmpty) {
      return null;
    }

    try {
      // Check if events box is open
      if (!Hive.isBoxOpen('events')) {
        return null;
      }
      
      // Open the events box
      final eventBox = Hive.box<Event>('events');
      
      // Find the event by matching the practice name to event name
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == selectedPractice) {
          matchedEvent = event;
          break;
        }
      }
      
      if (matchedEvent == null) {
        return null;
      }

      // Get the firearm ID from the code
      final firearmId = DropdownValues.getFirearmIdByCode(selectedFirearmId!);
      
      if (firearmId == null) {
        return null;
      }

      // Create a Firearm object to get the correct content (with overrides)
      final firearm = Firearm(
        id: firearmId,
        code: selectedFirearmId!,
        gunType: '', // Not needed for this operation
      );

      // Get the content for this firearm (applies overrides automatically)
      final content = matchedEvent.getContentForFirearm(firearm);

      // Return the max score from courseOfFire
      return content.courseOfFire.maxScore;
    } catch (e) {
      return null;
    }
  }

  /// Get the total rounds for the selected event/practice and firearm
  int? _getTotalRoundsForSelectedEvent() {
    final perTargetRounds = _getPerTargetRoundsForSelectedEvent();
    if (perTargetRounds == null || perTargetRounds.isEmpty) {
      return null;
    }

    return perTargetRounds.fold<int>(0, (sum, rounds) => sum + rounds);
  }

  /// Get required number of targets/scores for selected event based on score change trigger mode.
  int? _getRequiredTargetCountForSelectedEvent() {
    final perTargetRounds = _getPerTargetRoundsForSelectedEvent();
    if (perTargetRounds == null || perTargetRounds.isEmpty) {
      return null;
    }
    return perTargetRounds.length;
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required Color primaryColor,
    IconData? icon,
    bool isOutlined = false,
  }) {
    return Container(
      height: icon != null ? 56 : 64,
      decoration: BoxDecoration(
        gradient: isOutlined
            ? null
            : LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: isOutlined ? Border.all(color: primaryColor, width: 2) : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : Colors.transparent,
          foregroundColor: isOutlined ? primaryColor : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    
    // Cache these values so they're only calculated once per build
    final maxScore = _getMaxScoreForSelectedEvent();
    final requiredTargetCount = _getRequiredTargetCountForSelectedEvent();
    final eventTargetCount = requiredTargetCount ?? 1;
    if (widget.eventScoringMode) {
      _ensureTargetSlots(eventTargetCount);
    }
    // final totalRounds = _getTotalRoundsForSelectedEvent();

    // Cache the practices list at state level - only rebuild if list changes
    final practicesList = DropdownValues.practices;
    final currentHash = practicesList.join(',');
    if (_cachedPracticeItems.isEmpty ||
        _cachedPracticeListHash != currentHash) {
      _cachedPracticeListHash = currentHash;
      _cachedPracticeItems = practicesList
          .map((p) => DropdownMenuItem(
        value: p,
        child: Text(
          p.isEmpty ? 'Please select a Favorite' : p,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: p.isEmpty ? const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey) : null,
        ),
      ))
          .toList();
    }

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) {
            return;
          }
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        child: Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
          drawer: const AppDrawer(currentRoute: 'enter_score'),
          appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.scoringMode
              ? (widget.editEntry != null
                  ? "Edit Score"
                  : (widget.eventScoringMode ? "Event Scoring" : "Basic Scoring"))
              : "Enter Score",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: const [
          HelpIconButton(
            title: 'Enter Score Help',
            content: HelpContent.enterScoreScreen,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PreNotes Card (if prenotes exists and is not empty)
            if (!widget.scoringMode &&
                selectedPractice != null &&
                selectedPractice!.isNotEmpty &&
                selectedPractice != DropdownValues.freestyle)
              ..._buildPreNotesCard(context, primaryColor, isDark),
            
            // Session Details Card
            if (!widget.scoringMode)
              _buildSectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                            Icons.info_outline, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Session Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Date",
                      prefixIcon: Icon(
                          Icons.calendar_today, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    ),
                    controller: TextEditingController(
                      text: "${selectedDate.day}/${selectedDate
                          .month}/${selectedDate.year}",
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: primaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),

 // Practice Dropdown with Settings Icon
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('practice_$selectedPractice'),
                          value: selectedPractice,
                          items: _cachedPracticeItems,
                          onChanged: (v) async {
                            if (v != null) {
                              bool needsDialog = false;
                              
                              setState(() {
                                selectedPractice = v;
                                
                                // Check if current firearm is eligible for new practice
                                if (selectedFirearmId != null && selectedFirearmId!.isNotEmpty) {
                                  if (!_isFirearmEligibleForPractice(v, selectedFirearmId!)) {
                                    // Clear firearm selection if not eligible
                                    selectedFirearmId = DropdownValues.firearmIds.isNotEmpty 
                                        ? DropdownValues.firearmIds.first 
                                        : '';
                                    needsDialog = true;
                                  }
                                }
                              });
                              
                              // Show dialog after setState if needed
                              if (needsDialog && mounted) {
                                await _showEligibleFirearmsDialog(v);
                              }
                              
                              if (v.isNotEmpty) {
                                _saveSelection('lastPractice', v);
                              }
                            }
                          },
                          isDense: true,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: "Event / Practice",
                            prefixIcon: Icon(
                                Icons.track_changes, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey[800] : Colors
                                .grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.favorite, color: primaryColor),
                          tooltip: "Select Favorite Practices",
                          onPressed: () async {
                            await showPracticeSelectionDialog(
                              context: context,
                              onSelectionChanged: () {
                                setState(() {
                                  _cachedPracticeItems = [];
                                  _cachedPracticeListHash = '';
                                  final currentPractices = DropdownValues.practices;
                                  if (!currentPractices.contains(selectedPractice)) {
                                    selectedPractice = currentPractices.first;
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Show Event button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showEventDetailsDialog(
                          context: context,
                          practiceName: selectedPractice,
                          firearmCode: selectedFirearmId,
                        );
                      },
                      icon: Icon(Icons.article, color: primaryColor, size: 18),
                      label: Text(
                        'Show Event',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

 // Firearm Details Card
            if (!widget.scoringMode)
              _buildSectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FaIcon(FontAwesomeIcons.gun, color: primaryColor,
                            size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Firearm Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Select Firearm Dropdown
                  ValueListenableBuilder(
                    valueListenable: Hive.box<FirearmEntry>('firearms').listenable(),
                    builder: (context, Box<FirearmEntry> box, _) {
                      final personalFirearms = box.values.toList();

                      return DropdownButtonFormField<String>(
                        value: selectedPersonalFirearmId ?? 'manual',
                        isDense: true,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'manual',
                            child: Text(
                              'Enter Manually',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          ...personalFirearms.map((firearm) {
                            return DropdownMenuItem(
                              value: firearm.id,
                              child: Text(
                                firearm.nickname ?? 'Unnamed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) {
                        setState(() {
                          selectedPersonalFirearmId = v == 'manual' ? null : v;

                          if (v != null && v != 'manual') {
                            // Auto-populate from personal firearm
                            final selectedFirearm = personalFirearms.firstWhere(
                              (f) => f.id == v,
                              orElse: () => throw Exception('Firearm not found'),
                            );

                            // Populate caliber (only if not empty AND exists in dropdown)
                            if (selectedFirearm.caliber.isNotEmpty) {
                              final calibersList = DropdownValues.calibers;
                              if (calibersList.contains(selectedFirearm.caliber)) {
                                selectedCaliber = selectedFirearm.caliber;
                              }
                              // If not in favorites, leave as-is (user needs to add to favorites first)
                            }

                            // Populate Firearm ID from personal firearm's myFirearmID
                            // IMPORTANT: Only update if myFirearmID has a value AND exists in dropdown
                            if (selectedFirearm.myFirearmID != null &&
                                selectedFirearm.myFirearmID!.isNotEmpty) {
                              final firearmIdsList = DropdownValues.firearmIds;
                              if (firearmIdsList.contains(selectedFirearm.myFirearmID)) {
                                selectedFirearmId = selectedFirearm.myFirearmID;
                              }
                              // If not in favorites, leave as-is (user needs to add to favorites first)
                            }

                            // Populate firearm name (nickname) in the firearm controller
                            if (selectedFirearm.nickname?.isNotEmpty == true) {
                              firearmController.text = selectedFirearm.nickname!;
                            }
                          }
                        });
                      },
                        decoration: InputDecoration(
                          labelText: "Select Firearm",
                          labelStyle: const TextStyle(fontSize: 13),
                          prefixIcon: Icon(
                              Icons.person, color: primaryColor, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        ),
                      );
                    },
                  ),

                  // Caliber + Firearm ID row (shown only when "Enter Manually" is selected)
                  Visibility(
                    visible: _showManualFirearmFields,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('caliber_$selectedCaliber'),
                                value: selectedCaliber,
                                isDense: true,
                                isExpanded: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                items: DropdownValues.calibers
                                    .map((c) =>
                                    DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c.isEmpty ? 'Please select a Favorite' : c,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: c.isEmpty ? FontStyle.italic : FontStyle.normal,
                                          color: c.isEmpty ? Colors.grey : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => selectedCaliber = v);
                                  if (v != null) _saveSelection('lastCaliber', v);
                                },
                                decoration: InputDecoration(
                                  labelText: "Caliber",
                                  labelStyle: const TextStyle(fontSize: 13),
                                  prefixIcon: Icon(
                                      Icons.straighten, color: primaryColor,
                                      size: 20),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[800] : Colors
                                      .grey[50],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.favorite, color: primaryColor, size: 20),
                                tooltip: "Manage Favorite Calibers",
                                onPressed: () async {
                                  await showCaliberSelectionDialog(
                                    context: context,
                                    onSelectionChanged: () {
                                      setState(() {
                                        final currentCalibers = DropdownValues.calibers;
                                        if (!currentCalibers.contains(selectedCaliber)) {
                                          selectedCaliber = currentCalibers.first;
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('firearm_$selectedFirearmId'),
                                value: selectedFirearmId,
                                isDense: true,
                                isExpanded: true,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                items: DropdownValues.firearmIds
                                    .map((id) =>
                                    DropdownMenuItem(
                                      value: id,
                                      child: Text(
                                        id.isEmpty ? 'Please select a Favorite' : id,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: id.isEmpty ? FontStyle.italic : FontStyle.normal,
                                          color: id.isEmpty ? Colors.grey : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                    .toList(),
                                onChanged: (v) async {
                                  if (v != null && v.isNotEmpty) {
                                    // Check if firearm is eligible for current practice
                                    if (selectedPractice != null && selectedPractice!.isNotEmpty) {
                                      if (!_isFirearmEligibleForPractice(selectedPractice!, v)) {
                                        // Show dialog and don't change selection
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Firearm Not Eligible'),
                                            content: const Text('That firearm is not eligible for this event.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                        return; // Don't change the selection
                                      }
                                    }

                                    // Valid selection
                                    setState(() => selectedFirearmId = v);
                                    _saveSelection('lastFirearmId', v);
                                  } else {
                                    setState(() => selectedFirearmId = v);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: "Firearm ID",
                                  labelStyle: const TextStyle(fontSize: 13),
                                  prefixIcon: Icon(
                                      Icons.tag, color: primaryColor, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey[800] : Colors
                                      .grey[50],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.favorite, color: primaryColor, size: 20),
                                tooltip: "Select Favorite Firearms",
                                onPressed: () async {
                                  await showFirearmSelectionDialog(
                                    context: context,
                                    onSelectionChanged: () {
                                      setState(() {
                                        final currentFirearmIds = DropdownValues.firearmIds;
                                        if (!currentFirearmIds.contains(selectedFirearmId)) {
                                          selectedFirearmId = currentFirearmIds.first;
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

// Score, X and Additional Info Card
            if (widget.scoringMode)
              _buildSectionCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.stars, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Score & Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Number of targets/scores needed based on score change trigger mode
                  if (requiredTargetCount != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.amber[800], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Number of Targets needed : $requiredTargetCount',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Max Score Display (only if both practice and firearmId are selected)
                  if (maxScore != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.emoji_events, color: primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Text(
                                'Max score for this\nEvent/Practice',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                maxScore.toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20,),


                        ],
                      ),
                    ),
                  ],

                  if (widget.eventScoringMode) ...[
                    Builder(
                      builder: (_) {
                        final eventTotal = _targetScores.whereType<int>().fold<int>(0, (sum, s) => sum + s);
                        final eventXTotal = _targetXCounts.whereType<int>().fold<int>(0, (sum, x) => sum + x);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.summarize, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Total score for Event:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$eventTotal / X=$eventXTotal',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  if (widget.eventScoringMode) ...[
                    for (int i = 0; i < eventTargetCount; i++) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target ${i + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGradientButton(
                                    label: "Score\nCalculator",
                                    onPressed: () => _openScoreCalculatorForTarget(i),
                                    primaryColor: primaryColor,
                                    isOutlined: _targetScores[i] == null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGradientButton(
                                    label: "Basic\nScore",
                                    onPressed: () => _openBasicScoreForTarget(i, primaryColor),
                                    primaryColor: Colors.orange,
                                    isOutlined: _targetScores[i] == null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildGradientButton(
                              label: "Capture Target",
                              icon: Icons.camera_alt,
                              onPressed: () => _pickImageForTarget(i),
                              primaryColor: primaryColor,
                              isOutlined: _targetImages[i] == null,
                            ),
                            if (_targetScores[i] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Score: ${_targetScores[i]}${(_targetXCounts[i] ?? 0) > 0 ? '  X: ${_targetXCounts[i]}' : ''}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_targetImages[i] != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _targetImages[i]!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],

                  // Recorded Score Box (shows if score has been entered)
                  if (!widget.eventScoringMode && scoreController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Recorded Score',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    scoreController.text,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (xController.text.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.gps_fixed, color: Colors.amber[700], size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      xController.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    // Warning if score exceeds max
                    if (maxScore != null && int.tryParse(scoreController.text) != null &&
                        int.parse(scoreController.text) > maxScore) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Score too high for this event!',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  // Score Calculator and Basic Score Buttons
                  if (!widget.eventScoringMode)
                    Row(
                    children: [
                      Expanded(
                        child: _buildGradientButton(
                          label: "Score\nCalculator",
                          onPressed: () async {
                            final calcTotalRounds = _getTotalRoundsForSelectedEvent();
                            final result = await showScoreCalculatorDialog(
                              context: context,
                              totalRounds: calcTotalRounds,
                              selectedPractice: selectedPractice,
                              selectedFirearmId: selectedFirearmId,
                            );
                            if (result != null) {
                              setState(() {
                                scoreController.text = result.score.toString();
                                xController.text = result.xCount > 0 
                                    ? result.xCount.toString() 
                                    : '';
                                // Store the score breakdown for saving to Hive later
                                _scoreBreakdown = result.scoreCounts;
                              });
                            }
                          },
                          primaryColor: primaryColor,
                          isOutlined: scoreController.text.isEmpty,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGradientButton(
                          label: "Basic\nScore",
                          onPressed: () => _showBasicScoreDialog(context, primaryColor),
                          primaryColor: Colors.orange,
                          isOutlined: scoreController.text.isEmpty,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes Button (Full Width)
                  if (!widget.eventScoringMode)
                    SizedBox(
                    width: double.infinity,
                    child: _buildGradientButton(
                      label: "Notes",
                      icon: Icons.note,
                      onPressed: () {
                        showNotesDialog(
                          context: context,
                          notesController: notesController,
                        );
                      },
                      primaryColor: primaryColor,
                      isOutlined: notesController.text.isEmpty,
                    ),
                  ),
                ],
              ),
            ),

// Target Image Card (if captured)
            if (widget.scoringMode && !widget.eventScoringMode && targetImage != null)
              _buildSectionCard(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.photo_camera, color: primaryColor,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Target Image",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        targetImage!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

 // Action Buttons
            const SizedBox(height: 8),
            if (widget.scoringMode) ...[
              if (!widget.eventScoringMode)
                _buildGradientButton(
                label: "Capture Target",
                icon: Icons.camera_alt,
                onPressed: _pickImage,
                primaryColor: primaryColor,
                isOutlined: true,
              ),
              const SizedBox(height: 12),
              _buildGradientButton(
                label: widget.editEntry != null ? "Update Entry" : "Save Entry",
                icon: Icons.save,
                onPressed: _confirmSaveEntry,
                primaryColor: primaryColor,
              ),
            ] else ...[
              _buildGradientButton(
                label: "Basic Scoring",
                icon: Icons.calculate,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnterScoreScreen(
                        scoringMode: true,
                        initialDate: selectedDate,
                        initialPractice: selectedPractice,
                        initialCaliber: selectedCaliber,
                        initialFirearmId: selectedFirearmId,
                        initialFirearm: firearmController.text,
                      ),
                    ),
                  );
                },
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),
              _buildGradientButton(
                label: "Enter Score as Event",
                icon: Icons.flag,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventScoringScreen(
                        initialDate: selectedDate,
                        initialPractice: selectedPractice,
                        initialCaliber: selectedCaliber,
                        initialFirearmId: selectedFirearmId,
                        initialFirearm: firearmController.text,
                      ),
                    ),
                  );
                },
                primaryColor: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildGradientButton(
                label: "Cancel",
                icon: Icons.close,
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                primaryColor: Colors.grey,
                isOutlined: true,
              ),
            ],
            const SizedBox(height: 15),
          ],
        ),
      ),
      ),
    ),
    );
  }

  /// Show dialog with eligible firearms for the selected event
  Future<void> _showEligibleFirearmsDialog(String eventName) async {
    try {
      // Get the event from Hive
      if (!Hive.isBoxOpen('events')) return;
      
      final eventBox = Hive.box<Event>('events');
      Event? matchedEvent;
      
      for (final event in eventBox.values) {
        if (event.name == eventName) {
          matchedEvent = event;
          break;
        }
      }
      
      if (matchedEvent == null) return;
      
      // Get eligible firearm IDs
      final eligibleIds = matchedEvent.applicableFirearmIds;
      
      // Map IDs to FirearmInfo objects
      final eligibleFirearms = eligibleIds.map((id) {
        return DropdownValues.masterFirearmTable.firstWhere(
          (f) => f.id == id,
          orElse: () => FirearmInfo(id: id, code: 'Unknown ID: $id', gunType: ''),
        );
      }).toList();
      
      // Get favorite firearm IDs for comparison
      final favoriteIds = DropdownValues.favoriteFirearmIdsList;
      
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final primaryColor = themeProvider.primaryColor;
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Firearm Not Eligible'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The firearm you selected is not eligible for this event.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Eligible firearms:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: eligibleFirearms.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        final firearm = eligibleFirearms[index];
                        final isFavorite = favoriteIds.contains(firearm.id);
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isFavorite ? () {
                              // Set the firearm and close dialog
                              setState(() {
                                selectedFirearmId = firearm.code;
                              });
                              _saveSelection('lastFirearmId', firearm.code);
                              Navigator.pop(context);
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  if (isFavorite)
                                    Icon(
                                      Icons.star,
                                      color: primaryColor,
                                      size: 18,
                                    )
                                  else
                                    Icon(
                                      Icons.star_border,
                                      color: Colors.grey.shade400,
                                      size: 18,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firearm.code,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isFavorite ? FontWeight.bold : FontWeight.normal,
                                            color: isFavorite ? primaryColor : (isDark ? Colors.white : Colors.black87),
                                          ),
                                        ),
                                        if (firearm.gunType.isNotEmpty)
                                          Text(
                                            firearm.gunType,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isFavorite)
                                    Icon(
                                      Icons.touch_app,
                                      color: primaryColor.withValues(alpha: 0.5),
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, color: primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Starred firearms are in your favorites - tap to select',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Silently handle error
    }
  }

  /// Build PreNotes card if prenotes exists for the selected event
  List<Widget> _buildPreNotesCard(BuildContext context, Color primaryColor, bool isDark) {
    try {
      // Check if events box is open
      if (!Hive.isBoxOpen('events')) {
        return [];
      }
      
      final eventBox = Hive.box<Event>('events');
      
      // Find the event by matching the practice name to event name
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == selectedPractice) {
          matchedEvent = event;
          break;
        }
      }
      
      // If no event found or no prenotes, return empty
      if (matchedEvent == null || matchedEvent.prenotes == null) {
        return [];
      }
      
      final prenotes = matchedEvent.prenotes!;
      
      // Check if prenotes has content
      final hasTitle = prenotes.title != null && prenotes.title!.isNotEmpty;
      final hasText = prenotes.text != null && prenotes.text!.isNotEmpty;
      
      if (!hasTitle && !hasText) {
        return [];
      }
      
      // Build the prenotes card
      return [
        _buildSectionCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTitle) ...[
                Text(
                  prenotes.title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (hasText)
                Text(
                  prenotes.text!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// Show dialog for entering basic score and X count
  Future<void> _showBasicScoreDialog(BuildContext context, Color primaryColor) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _BasicScoreDialogContent(
          primaryColor: primaryColor,
          initialScore: scoreController.text,
          initialXCount: xController.text,
          maxScore: _getMaxScoreForSelectedEvent(),
        );
      },
    );

    if (result != null && mounted) {
      scoreController.text = result['score']!;
      xController.text = result['xCount']!;
      _scoreBreakdown = null;
      setState(() {});
    }
  }
}

/// Separate stateful widget for the basic score dialog to isolate its state
class _BasicScoreDialogContent extends StatefulWidget {
  final Color primaryColor;
  final String initialScore;
  final String initialXCount;
  final int? maxScore;

  const _BasicScoreDialogContent({
    required this.primaryColor,
    required this.initialScore,
    required this.initialXCount,
    this.maxScore,
  });

  @override
  State<_BasicScoreDialogContent> createState() => _BasicScoreDialogContentState();
}

class _BasicScoreDialogContentState extends State<_BasicScoreDialogContent> {
  late final TextEditingController scoreController;
  late final TextEditingController xController;

  @override
  void initState() {
    super.initState();
    scoreController = TextEditingController(text: widget.initialScore);
    xController = TextEditingController(text: widget.initialXCount);
  }

  @override
  void dispose() {
    scoreController.dispose();
    xController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        final enteredScore = int.tryParse(scoreController.text.trim());
        final isScoreTooHigh = widget.maxScore != null &&
            enteredScore != null &&
            enteredScore > widget.maxScore!;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: widget.primaryColor),
              const SizedBox(width: 8),
              const Text('Enter Score'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Score',
                    prefixIcon: Icon(Icons.military_tech, color: widget.primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isScoreTooHigh ? Colors.red : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isScoreTooHigh ? Colors.red : Colors.grey,
                      ),
                    ),
                    hintText: 'Enter total score',
                    errorText: isScoreTooHigh
                        ? 'Score too high! Max is ${widget.maxScore}'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: xController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'X Count (Optional)',
                    prefixIcon: Icon(Icons.gps_fixed, color: widget.primaryColor),
                    border: const OutlineInputBorder(),
                    hintText: 'Number of X shots',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'score': scoreController.text.trim(),
                  'xCount': xController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
