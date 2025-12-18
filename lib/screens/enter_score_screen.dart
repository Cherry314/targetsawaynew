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
import '../data/dropdown_values.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';
import '../services/calendar_score_service.dart';

import 'methods/competition_dialog.dart';
import 'methods/firearm_dialog.dart';
import 'methods/notes_dialog.dart';
import 'methods/practice_selection_dialog.dart';

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
  final firearmController = TextEditingController();
  final notesController = TextEditingController();
  final compIdController = TextEditingController();
  final compResultController = TextEditingController();

  String? selectedPractice;
  String? selectedCaliber;
  String? selectedFirearmId;

  File? targetImage;
  File? thumbnailImage;

  DateTime selectedDate = DateTime.now();

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
    firearmController.text = entry.firearm ?? '';
    notesController.text = entry.notes ?? '';
    compIdController.text = entry.compId ?? '';
    compResultController.text = entry.compResult ?? '';

    setState(() {
      // Validate that the practice exists in the dropdown list
      final currentPractices = DropdownValues.practices;
      if (!currentPractices.contains(entry.practice) &&
          entry.practice != 'All') {
        // If not in favorites, add it temporarily (setter will handle 'All' automatically)
        final practicesWithoutAll = currentPractices
            .where((p) => p != 'All')
            .toList();
        DropdownValues.practices = [entry.practice, ...practicesWithoutAll];
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
      // The setter will automatically filter out 'All' and add it at the top
      DropdownValues.practices = cleanedPractices;
    }

    setState(() {
      // Get the last selected practice
      // Only use editEntry values if NOT from calendar and values are not empty
      final lastPractice = (widget.editEntry?.practice != null &&
          widget.editEntry!.practice.isNotEmpty &&
          !widget.openedFromCalendar)
          ? widget.editEntry!.practice
          : prefs.getString('lastPractice');

      // Ensure the selected practice exists in the dropdown list
      if (lastPractice != null &&
          DropdownValues.practices.contains(lastPractice)) {
        selectedPractice = lastPractice;
      } else {
        selectedPractice = DropdownValues.practices.first;
      }

      // Only use editEntry caliber if NOT from calendar and not empty
      selectedCaliber = (widget.editEntry?.caliber != null &&
          widget.editEntry!.caliber.isNotEmpty &&
          !widget.openedFromCalendar)
          ? widget.editEntry!.caliber
          : (prefs.getString('lastCaliber') ?? DropdownValues.calibers.first);

      // Get the last firearm ID
      // Only use editEntry firearmId if NOT from calendar and not empty
      final lastFirearmId = (widget.editEntry?.firearmId != null &&
          widget.editEntry!.firearmId.isNotEmpty &&
          !widget.openedFromCalendar)
          ? widget.editEntry!.firearmId
          : prefs.getString('lastFirearmId');

      if (lastFirearmId != null &&
          DropdownValues.firearmIds.contains(lastFirearmId)) {
        selectedFirearmId = lastFirearmId;
      } else {
        selectedFirearmId = DropdownValues.firearmIds.first;
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

      // Clear optional fields
      firearmController.clear();
      notesController.clear();
      compIdController.clear();
      compResultController.clear();

      // Clear images
      targetImage = null;
      thumbnailImage = null;

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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Save"),
        content: Text(
            widget.openedFromCalendar
                ? "Do you want to save this entry and return to the Calendar?"
                : "Do you want to save this entry?"),
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
                firearmId: selectedFirearmId!,
                firearm: firearmController.text,
                notes: notesController.text,
                comp: compIsTrue,
                compId: compIdController.text,
                compResult: compResultController.text,
                targetFilePath: targetImage?.path,
                thumbnailFilePath: thumbnailImage?.path,
                targetCaptured: targetImage != null,
              );

              await box.put(newEntry.id, newEntry);

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
          p,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ))
          .toList();
    }

    return Scaffold(
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
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          onChanged: (v) {
                            setState(() => selectedPractice = v);
                            if (v != null) _saveSelection('lastPractice', v);
                          },
                          isDense: true,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: "Practice",
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
                          icon: Icon(Icons.settings, color: primaryColor),
                          tooltip: "Select Favorite Practices",
                          onPressed: () async {
                            await showPracticeSelectionDialog(
                              context: context,
                              onSelectionChanged: () {
                                setState(() {
                                  _cachedPracticeItems = [];
                                  _cachedPracticeListHash = '';
                                  final currentPractices = DropdownValues
                                      .practices;
                                  if (!currentPractices.contains(
                                      selectedPractice)) {
                                    selectedPractice = 'All';
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

                  // Caliber + Firearm ID row
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
                                  c,
                                  style: const TextStyle(fontSize: 14),
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
                      const SizedBox(width: 10),
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
                                  id,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => selectedFirearmId = v);
                            if (v != null) _saveSelection('lastFirearmId', v);
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
                    ],
                  ),
                ],
              ),
            ),

            // Score & Additional Info Card
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Score Input
                  TextFormField(
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
                  const SizedBox(height: 20),

                  // Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context: context,
                        icon: FontAwesomeIcons.gun,
                        label: "Firearm",
                        isActive: firearmController.text.isNotEmpty,
                        primaryColor: primaryColor,
                        onPressed: () {
                          showFirearmDialog(
                            context: context,
                            firearmController: firearmController,
                            onSelectId: (id) =>
                                setState(() => selectedFirearmId = id),
                            saveSelection: _saveSelection,
                          );
                        },
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.emoji_events,
                        label: "Competition",
                        isActive: compIdController.text.isNotEmpty ||
                            compResultController.text.isNotEmpty,
                        primaryColor: primaryColor,
                        onPressed: () {
                          showCompetitionDialog(
                            context: context,
                            compIdController: compIdController,
                            compResultController: compResultController,
                          );
                        },
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.note,
                        label: "Notes",
                        isActive: notesController.text.isNotEmpty,
                        primaryColor: primaryColor,
                        onPressed: () {
                          showNotesDialog(
                            context: context,
                            notesController: notesController,
                          );
                        },
                      ),
                    ],
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
    );
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
