// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models/score_entry.dart';
import 'models/firearm_entry.dart';
import 'models/membership_card_entry.dart';
import 'models/appointment_entry.dart';
import 'models/rounds_counter_entry.dart';
import 'models/comp_history_entry.dart';
import 'services/notification_service.dart';

// Hive model imports
import 'models/hive/event.dart';
import 'models/hive/event_content.dart';
import 'models/hive/event_override.dart';
import 'models/hive/override_content.dart';
import 'models/hive/firearm.dart';
import 'models/hive/target.dart';
import 'models/hive/ammunition.dart';
import 'models/hive/sight.dart';
import 'models/hive/position.dart';
import 'models/hive/ready_position.dart';
import 'models/hive/practice.dart';
import 'models/hive/stage.dart';
import 'models/hive/course_of_fire.dart';
import 'models/hive/event_notes.dart';
import 'models/hive/sighters.dart';
import 'models/hive/notes.dart';
import 'models/hive/scoring.dart';
import 'models/hive/loading.dart';
import 'models/hive/magazine.dart';
import 'models/hive/reloading.dart';
import 'models/hive/equipment.dart';
import 'models/hive/range_equipment.dart';
import 'models/hive/changing_position.dart';
import 'models/hive/range_command.dart';
import 'models/hive/tie.dart';
import 'models/hive/procedural_penalty.dart';
import 'models/hive/classification.dart';
import 'models/hive/target_id.dart';
import 'models/hive/target_position.dart';
import 'models/hive/practice_stage.dart';
import 'models/hive/zone.dart';
import 'models/hive/target_zone.dart';
import 'models/hive/target_info.dart';
import 'models/hive/prenotes.dart';
import 'models/hive/club.dart';

import 'screens/home_screen.dart';
import 'screens/enter_score_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/personal_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/event_picker_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/rounds_manager_screen.dart';
import 'screens/comps/comp_portal.dart';
import 'screens/comps/competition_history_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/security_setup_screen.dart';
import 'screens/auth/passcode_setup_screen.dart';
import 'screens/auth/app_unlock_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ScoreEntryAdapter()); // typeId:1
  Hive.registerAdapter(FirearmEntryAdapter()); // typeId:2
  Hive.registerAdapter(MembershipCardEntryAdapter()); // typeId:3
  Hive.registerAdapter(AppointmentEntryAdapter()); // typeId:4
  Hive.registerAdapter(RoundsCounterEntryAdapter()); // typeId:5
  Hive.registerAdapter(CompHistoryEntryAdapter()); // typeId:134

  // Register Hive adapters for Event system
  Hive.registerAdapter(EventAdapter()); // typeId:100
  Hive.registerAdapter(EventContentAdapter()); // typeId:101
  Hive.registerAdapter(EventOverrideAdapter()); // typeId:102
  Hive.registerAdapter(OverrideContentAdapter()); // typeId:103
  Hive.registerAdapter(FirearmAdapter()); // typeId:104
  Hive.registerAdapter(TargetAdapter()); // typeId:105
  Hive.registerAdapter(AmmunitionAdapter()); // typeId:106
  Hive.registerAdapter(SightAdapter()); // typeId:107
  Hive.registerAdapter(PositionAdapter()); // typeId:108
  Hive.registerAdapter(ReadyPositionAdapter()); // typeId:109
  Hive.registerAdapter(RangeCommandAdapter()); // typeId:110
  Hive.registerAdapter(TieAdapter()); // typeId:111
  Hive.registerAdapter(ProceduralPenaltyAdapter()); // typeId:112
  Hive.registerAdapter(ClassificationAdapter()); // typeId:113
  Hive.registerAdapter(TargetPositionAdapter()); // typeId:114
  Hive.registerAdapter(CourseOfFireAdapter()); // typeId:115
  Hive.registerAdapter(EventNotesAdapter()); // typeId:116
  Hive.registerAdapter(SightersAdapter()); // typeId:117
  Hive.registerAdapter(NotesAdapter()); // typeId:118
  Hive.registerAdapter(ScoringAdapter()); // typeId:119
  Hive.registerAdapter(LoadingAdapter()); // typeId:120
  Hive.registerAdapter(MagazineAdapter()); // typeId:121
  Hive.registerAdapter(ReloadingAdapter()); // typeId:122
  Hive.registerAdapter(EquipmentAdapter()); // typeId:123
  Hive.registerAdapter(RangeEquipmentAdapter()); // typeId:124
  Hive.registerAdapter(ChangingPositionAdapter()); // typeId:125
  Hive.registerAdapter(TargetIDAdapter()); // typeId:126
  Hive.registerAdapter(PracticeAdapter()); // typeId:127
  Hive.registerAdapter(StageAdapter()); // typeId:128
  Hive.registerAdapter(PracticeStageAdapter()); // typeId:129
  Hive.registerAdapter(ZoneAdapter()); // typeId:130
  Hive.registerAdapter(TargetZoneAdapter()); // typeId:131
  Hive.registerAdapter(TargetInfoAdapter()); // typeId:132
  Hive.registerAdapter(PreNotesAdapter()); // typeId:36
  Hive.registerAdapter(ClubAdapter()); // typeId:133

  // Open all boxes once at startup
  await Hive.openBox<ScoreEntry>('scores');
  await Hive.openBox<FirearmEntry>('firearms');
  await Hive.openBox<MembershipCardEntry>('membership_cards');
  await Hive.openBox<AppointmentEntry>('appointments');
  await Hive.openBox<RoundsCounterEntry>('rounds_counter');
  await Hive.openBox<CompHistoryEntry>('comp_history');

  // Open boxes for Event system
  await Hive.openBox<Event>('events');
  await Hive.openBox<Firearm>('firearms_hive');
  await Hive.openBox<TargetInfo>('target_info'); // Target zone scoring database
  await Hive.openBox<Club>('clubs'); // Clubs database

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

// RoundsCounterProvider manages whether rounds counter is enabled
class RoundsCounterProvider extends ChangeNotifier {
  bool _enabled = true; // Default to enabled
  bool get enabled => _enabled;

  RoundsCounterProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('roundsCounterEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('roundsCounterEnabled', value);
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
        ChangeNotifierProvider(create: (_) => RoundsCounterProvider()),
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
          home: StreamBuilder<firebase_auth.User?>(
            stream: AuthService().authStateChanges,
            builder: (context, snapshot) {
              // Show loading while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.grey[900]
                      : Colors.grey[50],
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 80,
                          color: themeProvider.primaryColor,
                        ),
                        const SizedBox(height: 24),
                        CircularProgressIndicator(
                          color: themeProvider.primaryColor,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // User is logged in
              if (snapshot.hasData) {
                return const AppUnlockScreen();
              }

              // User is not logged in
              return const LoginScreen();
            },
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegistrationScreen(),
            '/security_setup': (context) => const SecuritySetupScreen(),
            '/passcode_setup': (context) => const PasscodeSetupScreen(),
            '/app_unlock': (context) => const AppUnlockScreen(),
            '/home': (context) => const HomeScreen(),
            '/enter_score': (context) =>
                EnterScoreScreen(
                  key: ValueKey('enter_score_${DateTime
                      .now()
                      .millisecondsSinceEpoch}'),
                ),
            '/history': (context) => const HistoryScreen(),
            '/progress': (context) => const ProgressScreen(),
            '/stats': (context) => const StatsScreen(),
            '/calendar': (context) => const CalendarScreen(),
            '/personal': (context) => const PersonalScreen(),
            '/event_picker': (context) => const EventPickerScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/rounds_manager': (context) => const RoundsManagerScreen(),
            '/comps': (context) => const CompPortalScreen(),
            '/comp_history': (context) => const CompetitionHistoryScreen(),
          },
        ),
      ),
    );
  }
}
