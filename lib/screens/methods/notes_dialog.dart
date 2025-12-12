// lib/dialogs/notes_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

Future<void> showNotesDialog({
  required BuildContext context,
  required TextEditingController notesController,
}) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Notes",
          style: TextStyle(color: themeProvider.primaryColor)),
      content: TextField(
        controller: notesController,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          child: Text("OK", style: TextStyle(color: themeProvider.primaryColor)),
          onPressed: () => Navigator.pop(context),
        )
      ],
    ),
  );
}
