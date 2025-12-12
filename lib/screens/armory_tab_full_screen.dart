// lib/screens/armory_full_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/firearm_entry.dart';

class ArmoryFullScreen extends StatefulWidget {
  final FirearmEntry entry;
  const ArmoryFullScreen({super.key, required this.entry});

  @override
  State<ArmoryFullScreen> createState() => _ArmoryFullScreenState();
}

class _ArmoryFullScreenState extends State<ArmoryFullScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final imagePath = entry.imagePath;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              children: [
                // Fullscreen image
                if (imagePath != null && File(imagePath).existsSync())
                  Positioned.fill(
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'No image available',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),

                // Overlay with details
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nickname: ${entry.nickname ?? "-"}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Make: ${entry.make}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Model: ${entry.model}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Calibre: ${entry.caliber}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Scope: ${entry.scopeSize ?? "-"}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Owned: ${entry.owned == true ? "Yes" : "No"}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Notes:',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text(entry.notes!,
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
