import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

    return Scaffold(
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
                  offset: Offset(dx, dy -96),
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
                        width: screenSize.width * 0.5, // adjust size as needed
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
    );
  }
}
