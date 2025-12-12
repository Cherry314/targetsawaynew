// lib/dialogs/competition_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

Future<void> showCompetitionDialog({
  required BuildContext context,
  required TextEditingController compIdController,
  required TextEditingController compResultController,
}) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Competition Result",
          style: TextStyle(color: themeProvider.primaryColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: compIdController,
            decoration: InputDecoration(
              labelText: "Competition ID",
              labelStyle: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: compResultController,
            decoration: InputDecoration(
              labelText: "Competition Result",
              labelStyle: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
        ],
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
