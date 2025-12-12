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
import '../data/dropdown_values.dart';
import '../main.dart';

import 'methods/competition_dialog.dart';
import 'methods/firearm_dialog.dart';
import 'methods/notes_dialog.dart';

class EnterScoreScreen extends StatefulWidget {
  final ScoreEntry? editEntry;

  const EnterScoreScreen({super.key, this.editEntry});

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

  @override
  void initState() {
    super.initState();
    _loadLastSelections();

    if (widget.editEntry != null) _populateEditFields();
    if (widget.editEntry != null) selectedDate = widget.editEntry!.date;

    firearmController.addListener(() => setState(() {}));
    notesController.addListener(() => setState(() {}));
    compIdController.addListener(() => setState(() {}));
    compResultController.addListener(() => setState(() {}));
  }

  void _populateEditFields() {
    final entry = widget.editEntry!;
    scoreController.text = entry.score.toString();
    firearmController.text = entry.firearm ?? '';
    notesController.text = entry.notes ?? '';
    compIdController.text = entry.compId ?? '';
    compResultController.text = entry.compResult ?? '';

    selectedPractice = entry.practice;
    selectedCaliber = entry.caliber;
    selectedFirearmId = entry.firearmId;

    targetImage = entry.targetFilePath != null ? File(entry.targetFilePath!) : null;
    thumbnailImage =
    entry.thumbnailFilePath != null ? File(entry.thumbnailFilePath!) : null;
  }

  Future<void> _loadLastSelections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPractice = widget.editEntry?.practice ??
          prefs.getString('lastPractice') ??
          DropdownValues.practices.first;

      selectedCaliber = widget.editEntry?.caliber ??
          prefs.getString('lastCaliber') ??
          DropdownValues.calibers.first;

      selectedFirearmId = widget.editEntry?.firearmId ??
          prefs.getString('lastFirearmId') ??
          DropdownValues.firearmIds.first;
    });
  }

  Future<void> _saveSelection(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

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
        content: const Text(
            "Do you want to save this entry and return to the Home Screen?"),
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
                    DateTime.now().millisecondsSinceEpoch.toString(),
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

              if (!mounted) return;

              Navigator.pop(context); // close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;

    final firearmBox = Hive.box<FirearmEntry>('firearms');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editEntry != null ? "Edit Score" : "Enter Score"),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Picker
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Date",
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                        text:
                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: primaryColor),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Practice Dropdown
            DropdownButtonFormField<String>(
              initialValue: selectedPractice,
              items: DropdownValues.practices
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                setState(() => selectedPractice = v);
                if (v != null) _saveSelection('lastPractice', v);
              },
              decoration: const InputDecoration(
                labelText: "Practice",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Caliber + Firearm ID row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCaliber,
                    items: DropdownValues.calibers
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedCaliber = v);
                      if (v != null) _saveSelection('lastCaliber', v);
                    },
                    decoration: const InputDecoration(
                      labelText: "Caliber",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedFirearmId, // <<< Fixes the red-screen dropdown error
                    items: firearmBox.values
                        .map((gun) => DropdownMenuItem(
                      value: gun.id,
                      child: Text(gun.nickname ?? "Unnamed"),
                    ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedFirearmId = v);
                      if (v != null) _saveSelection('lastFirearmId', v);
                    },
                    decoration: const InputDecoration(
                      labelText: "Firearm ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Score + Dialog Buttons
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Score",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Firearm dialog button
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.gun,
                      color: iconColor(firearmController.text.isNotEmpty)),
                  tooltip: "Enter Firearm",
                  onPressed: () {
                    showFirearmDialog(
                      context: context,
                      firearmController: firearmController,
                      onSelectId: (id) => setState(() => selectedFirearmId = id),
                      saveSelection: _saveSelection,
                    );
                  },
                ),

                // Competition dialog button
                IconButton(
                  icon: Icon(
                    Icons.emoji_events,
                    color: iconColor(compIdController.text.isNotEmpty ||
                        compResultController.text.isNotEmpty),
                  ),
                  tooltip: "Competition Result",
                  onPressed: () {
                    showCompetitionDialog(
                      context: context,
                      compIdController: compIdController,
                      compResultController: compResultController,
                    );
                  },
                ),

                // Notes dialog button
                IconButton(
                  icon: Icon(Icons.note,
                      color: iconColor(notesController.text.isNotEmpty)),
                  tooltip: "Enter Notes",
                  onPressed: () {
                    showNotesDialog(
                      context: context,
                      notesController: notesController,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Capture target + Save buttons
            LayoutBuilder(builder: (context, constraints) {
              bool wide = constraints.maxWidth > 400;

              var captureBtn = ElevatedButton.icon(
                icon: Icon(Icons.camera_alt),
                label: Text("Capture Target"),
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              );

              var saveBtn = ElevatedButton(
                onPressed: _confirmSaveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child:
                Text(widget.editEntry != null ? "Update Entry" : "Save Entry"),
              );

              return wide
                  ? Row(
                children: [
                  Expanded(child: captureBtn),
                  const SizedBox(width: 12),
                  Expanded(child: saveBtn),
                ],
              )
                  : Column(
                children: [
                  captureBtn,
                  const SizedBox(height: 12),
                  saveBtn,
                ],
              );
            }),

            const SizedBox(height: 20),

            if (targetImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  targetImage!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
