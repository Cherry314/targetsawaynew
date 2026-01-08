// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/score_entry.dart';
import 'models/firearm_entry.dart';
import 'models/membership_card_entry.dart';
import 'models/appointment_entry.dart';
import 'services/notification_service.dart';

import 'screens/home_screen.dart';
import 'screens/enter_score_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/personal_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/event_picker_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ScoreEntryAdapter()); // typeId:1
  Hive.registerAdapter(FirearmEntryAdapter()); // typeId:2
  Hive.registerAdapter(MembershipCardEntryAdapter()); // typeId:3
  Hive.registerAdapter(AppointmentEntryAdapter()); // typeId:4

  // Open all boxes once at startup
  await Hive.openBox<ScoreEntry>('scores');
  await Hive.openBox<FirearmEntry>('firearms');
  await Hive.openBox<MembershipCardEntry>('membership_cards');
  await Hive.openBox<AppointmentEntry>('appointments');

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

// ThemeProvider now includes themeIndex for SettingsScreen
class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = Colors.blue;
  Color get primaryColor => _primaryColor;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  int _themeIndex = 0;
  int get themeIndex => _themeIndex;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme index (color scheme)
    _themeIndex = prefs.getInt('themeIndex') ?? 0;
    _primaryColor = _colorFromIndex(_themeIndex);

    // Load theme mode (dark/light/system)
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = _themeModeFromString(themeModeString);

    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(mode));
  }

  Future<void> setTheme(int index) async {
    _themeIndex = index;
    _primaryColor = _colorFromIndex(index);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeIndex', index);
  }

  Color _colorFromIndex(int index) {
    switch (index) {
      case 1:
        return Colors.purple;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}

// ImageQualityProvider manages the saved image quality setting
class ImageQualityProvider extends ChangeNotifier {
  int _qualityIndex = 1; // Default to Medium (70%)
  int get qualityIndex => _qualityIndex;

  // Returns the quality percentage as an integer (50, 70, or 85)
  int get qualityPercentage {
    switch (_qualityIndex) {
      case 0:
        return 50; // Low
      case 1:
        return 70; // Medium
      case 2:
        return 85; // Large
      default:
        return 70; // Default to Medium
    }
  }

  String get qualityName {
    switch (_qualityIndex) {
      case 0:
        return 'Low (50%)';
      case 1:
        return 'Medium (70%)';
      case 2:
        return 'Large (85%)';
      default:
        return 'Medium (70%)';
    }
  }

  void setQuality(int index) {
    _qualityIndex = index;
    notifyListeners();
  }
}

// AnimationsProvider manages whether home screen animations are enabled
class AnimationsProvider extends ChangeNotifier {
  bool _animationsEnabled = true; // Default to enabled
  bool get animationsEnabled => _animationsEnabled;

  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ImageQualityProvider()),
        ChangeNotifierProvider(create: (_) => AnimationsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Target Scoring',
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light().copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: themeProvider.primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.primaryColor,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: themeProvider.primaryColor,
              ),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: themeProvider.primaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.primaryColor,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: themeProvider.primaryColor,
              ),
            ),
          ),
          initialRoute: '/home',
          routes: {
            '/home': (context) => const HomeScreen(),
            '/enter_score': (context) =>
                EnterScoreScreen(
                  key: ValueKey('enter_score_${DateTime
                      .now()
                      .millisecondsSinceEpoch}'),
                ),
            '/history': (context) => const HistoryScreen(),
            '/progress': (context) => const ProgressScreen(),
            '/calendar': (context) => const CalendarScreen(),
            '/personal': (context) => const PersonalScreen(),
            '/event_picker': (context) => const EventPickerScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        ),
      ),
    );
  }
}
