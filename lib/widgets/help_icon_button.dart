// lib/widgets/help_icon_button.dart

import 'package:flutter/material.dart';

/// A reusable help icon button that shows screen-specific help content
class HelpIconButton extends StatelessWidget {
  final String title;
  final String content;
  final Color? iconColor;

  const HelpIconButton({
    super.key,
    required this.title,
    required this.content,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: iconColor),
      tooltip: 'Help',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.help, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it!'),
                  ),
                ],
              ),
        );
      },
    );
  }
}
