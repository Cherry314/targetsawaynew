// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/score_entry.dart';
import 'screens/home_screen.dart';
import 'screens/enter_score_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';
import 'models/firearm_entry.dart';
import 'models/membership_card_entry.dart';
import 'screens/personal_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();



  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ScoreEntryAdapter()); // typeId:1
  Hive.registerAdapter(FirearmEntryAdapter()); // typeId:2
  Hive.registerAdapter(MembershipCardEntryAdapter());


  // Open Hive boxes
  await Hive.openBox<ScoreEntry>('scores');
  await Hive.openBox<FirearmEntry>('firearms'); // new box for firearms
  await Hive.openBox<MembershipCardEntry>('membership_cards'); // new box for firearms
  runApp(const MyApp());
}

// ThemeProvider now includes themeIndex for SettingsScreen
class ThemeProvider extends ChangeNotifier {
  // current primary color
  Color _primaryColor = Colors.blue;
  Color get primaryColor => _primaryColor;

  // theme mode
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // theme index (optional, for legacy dropdowns)
  int _themeIndex = 0;
  int get themeIndex => _themeIndex;

  // Set primary color dynamically
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  // Set theme mode (Light / Dark / System)
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Optional: set theme by index (legacy)
  void setTheme(int index) {
    _themeIndex = index;
    _primaryColor = _colorFromIndex(index);
    notifyListeners();
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Target Scoring',
          themeMode: themeProvider.themeMode,
          // Light Theme
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
          // Dark Theme
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
          home: const MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const EnterScoreScreen(),
      const HistoryScreen(),
      const ProgressScreen(),
      const PersonalScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = themeProvider.primaryColor;

    return SafeArea(
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          selectedItemColor: selectedColor,
          unselectedItemColor: Colors.grey,
          iconSize: 28,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Enter Score'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal'), // <-- Personal
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
