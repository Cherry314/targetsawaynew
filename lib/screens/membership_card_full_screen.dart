// lib/screens/membership_card_full_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/membership_card_entry.dart';

class MembershipCardFullScreen extends StatefulWidget {
  final MembershipCardEntry entry;
  const MembershipCardFullScreen({super.key, required this.entry});

  @override
  State<MembershipCardFullScreen> createState() => _MembershipCardFullScreenState();
}

class _MembershipCardFullScreenState extends State<MembershipCardFullScreen> {
  bool showFront = true;

  void _toggleCard() {
    setState(() {
      showFront = !showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frontImagePath = widget.entry.frontImagePath;
    final backImagePath = widget.entry.backImagePath;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Tap image to turn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onTap: _toggleCard,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) {
                      final rotateAnim = Tween(begin: 1.0, end: 0.0).animate(animation);
                      return AnimatedBuilder(
                        animation: rotateAnim,
                        child: child,
                        builder: (context, child) {
                          final angle = rotateAnim.value * 3.1416; // radians
                          return Transform(
                            transform: Matrix4.rotationY(angle),
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                      );
                    },
                    child: showFront
                        ? _buildImage(frontImagePath, key: const ValueKey('front'))
                        : _buildImage(backImagePath, key: const ValueKey('back')),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
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
    );
  }

  Widget _buildImage(String? path, {required Key key}) {
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        key: key,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return const Center(
        key: ValueKey('empty'),
        child: Text(
          'No image available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
}
