import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';
import '../services/data_sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final DataSyncService _dataSyncService = DataSyncService();

  final double swayAmount = 10;
  final double tremorAmount = 2;
  final double breathingAmount = 4;
  final int cycleMs = 5000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: cycleMs),
    )
      ..repeat();
    
    // Check for data updates from Firestore
    _checkForDataUpdates();
  }

  /// Check for data updates from Firebase
  Future<void> _checkForDataUpdates() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final isUpdateAvailable = await _dataSyncService.isUpdateAvailable();

      if (isUpdateAvailable && mounted) {
        // Show dialog to user about available update
        final shouldUpdate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.cloud_download, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('New Data Available'),
                ],
              ),
              content: const Text(
                'A new version of the shooting rules and target data is available. '
                'Would you like to download it now?\n\n'
                'This will update your event rules and target data.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Now'),
                ),
              ],
            );
          },
        );

        if (shouldUpdate == true && mounted) {
          await _downloadDataUpdate();
        }
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience
    }
  }

  /// Download and apply data update
  Future<void> _downloadDataUpdate() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Downloading update...'),
                  ],
                ),
              ),
            ),
          );
        },
      );

      final results = await _dataSyncService.downloadAndReplaceData();

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        final eventCount = results['events'] ?? 0;
        final targetCount = results['targets'] ?? 0;
        final clubCount = results['clubs'] ?? 0;

        // Show success notification
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Update Complete'),
                ],
              ),
              content: Text(
                'Successfully downloaded:\n'
                '• $eventCount events\n'
                '• $targetCount targets\n'
                '• $clubCount clubs\n\n'
                'Your data is now up to date!',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Update Failed'),
                ],
              ),
              content: Text(
                'Failed to download update: $e\n\n'
                'Please try again later or check your internet connection.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsEnabled = Provider
        .of<AnimationsProvider>(context)
        .animationsEnabled;
    if (animationsEnabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animationsEnabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _smoothNoise(double t, double seed) {
    return sin((t + seed) * 2 * pi) * 0.5 +
        sin((t * 0.5 + seed * 2) * 2 * pi) * 0.3 +
        sin((t * 0.25 + seed * 3) * 2 * pi) * 0.2;
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Exit Application'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<ThemeProvider>(context);
    // final primaryColor = themeProvider.primaryColor;
    final animationsEnabled = Provider
        .of<AnimationsProvider>(context)
        .animationsEnabled;
    final bgColor = Colors.black; // Black background under range.jpg
    final screenSize = MediaQuery
        .of(context)
        .size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Targets Away',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        drawer: const AppDrawer(currentRoute: 'home'),
        body: SafeArea(
          bottom: true,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final t = _controller.value;
              double dx = 0;
              double dy = 0;

              // Only calculate animation offsets if animations are enabled
              if (animationsEnabled) {
                dx = sin(t * 2 * pi) * swayAmount;
                dy = sin(t * 2 * pi * 0.6) * swayAmount;
                dy += breathingAmount * sin(t * 2 * pi * 0.25);
                dx += _smoothNoise(t, 0.8) * tremorAmount;
                dy += _smoothNoise(t, 1.3) * tremorAmount;
              }

              return Stack(
                children: [
                  // Black background
                  Container(color: bgColor),

                  // New background image stretched horizontally, keeping aspect ratio
                  Center(
                    child: Image.asset(
                      'assets/range1.jpg',
                      width: screenSize.width,
                      fit: BoxFit.fitWidth,
                    ),
                  ),

                  // Existing homeback2.png with modulated color


                  // Existing animated front image
                  Center(
                    child: Transform.translate(
                      offset: Offset(dx, dy - 96),
                      child: Image.asset(
                        'assets/homefront.png',
                        width: screenSize.width * 0.65,
                        fit: BoxFit.contain,
                        //color: primaryColor.withAlpha((0.09 * 255).round()),
                        colorBlendMode: BlendMode.modulate,
                      ),
                    ),
                  ),

                  // Black block overlay at bottom 1/3 of screen
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: screenSize.height / 3,
                    child: Container(
                      color: Colors.black, // fully black
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/targetsaway.png',
                            width: screenSize.width * 0.5,
                            // adjust size as needed
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Firearm Scoring Database',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
