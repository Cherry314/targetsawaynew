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

class EnterScoreScreen extends StatefulWidget {
  final ScoreEntry? editEntry;
  final bool openedFromCalendar;

  const EnterScoreScreen({
    super.key,
    this.editEntry,
    this.openedFromCalendar = false,
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

  void _confirmSaveEntry() async {
    final scoreValid = scoreController.text.isNotEmpty &&
        int.tryParse(scoreController.text) != null;

    if (!scoreValid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid score")));
      return;
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
    if (_scoreBreakdown != null) {
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

                  final newEntry = ScoreEntry(
                    id: widget.editEntry?.id ??
                        DateTime
                            .now()
                            .millisecondsSinceEpoch
                            .toString(),
                    date: selectedDate,
                    score: int.parse(scoreController.text),
                    practice: selectedPractice!,
                    caliber: selectedCaliber!,
                    firearmId: selectedFirearmId ?? '',
                    firearm: firearmController.text,
                    notes: notesController.text,
                    comp: compIsTrue,
                    compId: compIdController.text,
                    compResult: compResultController.text,
                    targetFilePath: targetImage?.path,
                    thumbnailFilePath: thumbnailImage?.path,
                    targetCaptured: targetImage != null,
                    x: xController.text.isNotEmpty ? int.tryParse(xController.text) : null,
                    // Score breakdown from calculator (if available)
                    scoreX: _scoreBreakdown != null && xController.text.isNotEmpty
                        ? int.tryParse(xController.text)
                        : null,
                    score10: _scoreBreakdown?[10],
                    score9: _scoreBreakdown?[9],
                    score8: _scoreBreakdown?[8],
                    score7: _scoreBreakdown?[7],
                    score6: _scoreBreakdown?[6],
                    score5: _scoreBreakdown?[5],
                    score4: _scoreBreakdown?[4],
                    score3: _scoreBreakdown?[3],
                    score2: _scoreBreakdown?[2],
                    score1: _scoreBreakdown?[1],
                    score0: _scoreBreakdown?[0],
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

                  if (!mounted) return;

                  Navigator.pop(context); // close dialog

                  if (widget.openedFromCalendar) {
                    // Return to calendar screen
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/calendar', (route) => false);
                  } else {
                    // Clear form and stay on screen for next entry
                    _resetFormForNextEntry();
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
    // Return null if Freestyle is selected (no total rounds for freestyle)
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

      // Return the total rounds from courseOfFire
      return content.courseOfFire.totalRounds;
    } catch (e) {
      return null;
    }
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required Color primaryColor,
    IconData? icon,
    bool isOutlined = false,
  }) {
    return Container(
      height: 56,
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
    final totalRounds = _getTotalRoundsForSelectedEvent();

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
          widget.editEntry != null ? "Edit Score" : "Enter Score",
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
            if (selectedPractice != null && selectedPractice!.isNotEmpty && selectedPractice != DropdownValues.freestyle)
              ..._buildPreNotesCard(context, primaryColor, isDark),
            
            // Session Details Card
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
                      const Spacer(),
                      // Event Details Icon Button
                      IconButton(
                        icon: Icon(Icons.article, color: primaryColor),
                        tooltip: "View Event Details",
                        onPressed: () {
                          showEventDetailsDialog(
                            context: context,
                            practiceName: selectedPractice,
                            firearmCode: selectedFirearmId,
                          );
                        },
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
                ],
              ),
            ),

 // Firearm Details Card
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

                              // Populate caliber (only if not empty)
                              if (selectedFirearm.caliber.isNotEmpty) {
                                selectedCaliber = selectedFirearm.caliber;
                              }

                              // Populate Firearm ID from personal firearm's myFirearmID
                              // IMPORTANT: Only update if myFirearmID has a value
                              // If it's null/empty, keep the current selectedFirearmId
                              if (selectedFirearm.myFirearmID != null && 
                                  selectedFirearm.myFirearmID!.isNotEmpty) {
                                selectedFirearmId = selectedFirearm.myFirearmID;
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
                      // Score Calculator Icon Button
                      IconButton(
                        icon: Icon(Icons.calculate, color: primaryColor),
                        tooltip: "Score Calculator",
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Max Score Display (only if both practice and firearmId are selected)
                  if (maxScore != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
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

// Score and X Input Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: scoreController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: "Score",
                            prefixIcon: Icon(
                                Icons.military_tech, color: primaryColor),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: xController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                                Icons.gps_fixed, color: primaryColor),
                            labelText: "X",
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notes Button (Full Width)
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
            if (targetImage != null)
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

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color primaryColor,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? primaryColor.withValues(alpha: 0.1)
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? primaryColor : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight
                          .normal,
                      color: isActive ? primaryColor : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
