// lib/screens/personal_screen.dart
import 'package:flutter/material.dart';
import 'armory_tab.dart';
import 'membership_cards_tab.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> myTabs = const [
    Tab(text: 'Armory'),
    Tab(text: 'Membership Cards'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[200];

    // Interpolate between background and AppBar color
    final tabBarColor = Color.lerp(bgColor, primaryColor, 0.3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Personal'),
        backgroundColor: primaryColor,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: tabBarColor, // blended shade
            child: TabBar(
              controller: _tabController,
              tabs: myTabs,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ArmoryTab(primaryColor: primaryColor),
          MembershipCardsTab(primaryColor: primaryColor),
        ],
      ),
    );
  }
}
