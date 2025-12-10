// lib/screens/enter_score_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../models/score_entry.dart';
import '../models/firearm_entry.dart';
import '../data/dropdown_values.dart';
import 'package:provider/provider.dart';
import '../main.dart';

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
    if (widget.editEntry != null) {
      selectedDate = widget.editEntry!.date;
    }
  }

  void _populateEditFields() {
    final entry = widget.editEntry!;
    scoreController.text = entry.score.toString();
    firearmController.text = entry.firearm ?? '';
    notesController.text = entry.notes ?? '';
    selectedPractice = entry.practice;
    selectedCaliber = entry.caliber;
    selectedFirearmId = entry.firearmId;
    targetImage = entry.targetFilePath != null ? File(entry.targetFilePath!) : null;
    thumbnailImage = entry.thumbnailFilePath != null ? File(entry.thumbnailFilePath!) : null;
  }

  Future<void> _loadLastSelections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPractice = (widget.editEntry?.practice.isNotEmpty ?? false)
          ? widget.editEntry!.practice
          : prefs.getString('lastPractice') ??
          (DropdownValues.practices.length > 1
              ? DropdownValues.practices[1]
              : DropdownValues.practices.first);

      selectedCaliber = (widget.editEntry?.caliber.isNotEmpty ?? false)
          ? widget.editEntry!.caliber
          : prefs.getString('lastCaliber') ??
          (DropdownValues.calibers.length > 1
              ? DropdownValues.calibers[1]
              : DropdownValues.calibers.first);

      selectedFirearmId = (widget.editEntry?.firearmId?.isNotEmpty ?? false)
          ? widget.editEntry!.firearmId!
          : prefs.getString('lastFirearmId') ??
          (DropdownValues.firearmIds.length > 1
              ? DropdownValues.firearmIds[1]
              : DropdownValues.firearmIds.first);
    });
  }

  Future<void> _saveSelection(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Generate a thumbnail from a full-size image
  Future<File> _generateThumbnail(File originalImage) async {
    final bytes = await originalImage.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final thumbnail = img.copyResize(image, width: 150); // small width

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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showTextInputDialog({
    required String title,
    required TextEditingController controller,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(title, style: TextStyle(color: themeProvider.primaryColor)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: themeProvider.primaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: themeProvider.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showFirearmDialog() {
    final firearmBox = Hive.box<FirearmEntry>('firearms');
    TextEditingController controller = firearmController;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Enter Firearm', style: TextStyle(color: themeProvider.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: themeProvider.primaryColor),
              decoration: InputDecoration(
                labelText: 'Firearm',
                labelStyle: TextStyle(color: themeProvider.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final firearms = firearmBox.values.toList();
                if (firearms.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No firearms found!')),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    title: Text('My Armoury', style: TextStyle(color: themeProvider.primaryColor)),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: firearms.length,
                        itemBuilder: (context, index) {
                          final gun = firearms[index];
                          final nickname = gun.nickname ?? 'Unnamed';
                          return ListTile(
                            title: Text(nickname, style: TextStyle(color: themeProvider.primaryColor)),
                            onTap: () {
                              controller.text = nickname;
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              icon: FaIcon(FontAwesomeIcons.gun, color: themeProvider.primaryColor),
              label: Text('My Armoury', style: TextStyle(color: themeProvider.primaryColor)),
              style: ElevatedButton.styleFrom(foregroundColor: themeProvider.primaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: themeProvider.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _saveEntry() async {
    if (scoreController.text.isEmpty || int.tryParse(scoreController.text) == null) {
      if (!mounted) return; // guard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid score')),
      );
      return;
    }

    final box = Hive.box<ScoreEntry>('scores');

    final newEntry = ScoreEntry(
      id: widget.editEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      score: int.parse(scoreController.text),
      practice: selectedPractice!,
      caliber: selectedCaliber!,
      firearmId: selectedFirearmId!,
      firearm: firearmController.text,
      notes: notesController.text,
      targetFilePath: targetImage?.path,
      thumbnailFilePath: thumbnailImage?.path,
      targetCaptured: targetImage != null,
    );

    await box.put(newEntry.id, newEntry);

    await _saveSelection('lastPractice', selectedPractice!);
    await _saveSelection('lastCaliber', selectedCaliber!);
    await _saveSelection('lastFirearmId', selectedFirearmId!);

    // Safe use of context after async
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editEntry != null ? 'Score entry updated' : 'Score entry saved'),
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newEntry);
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editEntry != null ? 'Edit Score' : 'Enter Score'),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ------------------- Date Field -------------------
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: primaryColor),
                        border: const OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      ),
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: primaryColor),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Practice Dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedPractice,
                decoration: InputDecoration(
                  labelText: 'Practice',
                  labelStyle: TextStyle(color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
                items: DropdownValues.practices
                    .map((p) => DropdownMenuItem(
                    value: p, child: Text(p, style: TextStyle(color: primaryColor))))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedPractice = v!);
                  _saveSelection('lastPractice', v!);
                },
              ),
              const SizedBox(height: 8),

              // Row: Caliber + Firearm ID
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCaliber,
                      decoration: InputDecoration(
                        labelText: 'Caliber',
                        labelStyle: TextStyle(color: primaryColor),
                        border: const OutlineInputBorder(),
                      ),
                      items: DropdownValues.calibers
                          .map((c) => DropdownMenuItem(
                          value: c, child: Text(c, style: TextStyle(color: primaryColor))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => selectedCaliber = v!);
                        _saveSelection('lastCaliber', v!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedFirearmId,
                      decoration: InputDecoration(
                        labelText: 'Firearm ID',
                        labelStyle: TextStyle(color: primaryColor),
                        border: const OutlineInputBorder(),
                      ),
                      items: DropdownValues.firearmIds
                          .map((f) => DropdownMenuItem(
                          value: f, child: Text(f, style: TextStyle(color: primaryColor))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => selectedFirearmId = v!);
                        _saveSelection('lastFirearmId', v!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row: Score, Firearm (icon), Notes (icon)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: scoreController,
                      decoration: InputDecoration(
                        labelText: 'Score',
                        labelStyle: TextStyle(color: primaryColor),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.gun, color: primaryColor),
                    tooltip: 'Enter Firearm',
                    onPressed: _showFirearmDialog,
                  ),
                  IconButton(
                    icon: Icon(Icons.note, color: primaryColor),
                    tooltip: 'Enter Notes',
                    onPressed: () => _showTextInputDialog(
                        title: 'Notes', controller: notesController),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Capture Target Image + Save Entry
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capture Target'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: primaryColor,
                      ),
                      child: Text(widget.editEntry != null ? 'Update Entry' : 'Save Entry'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thumbnail below buttons
              if (thumbnailImage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.file(thumbnailImage!, fit: BoxFit.cover),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
