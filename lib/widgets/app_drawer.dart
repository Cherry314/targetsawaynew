// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.gps_fixed,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Targets Away',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Firearm Scoring Database',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.home,
            title: 'Home',
            route: 'home',
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.edit,
            title: 'Enter Score',
            route: 'enter_score',
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history,
            title: 'History',
            route: 'history',
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.auto_graph,
            title: 'Progress',
            route: 'progress',
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.calendar_today,
            title: 'Calendar',
            route: 'calendar',
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.person,
            title: 'Personal',
            route: 'personal',
            primaryColor: primaryColor,
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            route: 'settings',
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required Color primaryColor,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: primaryColor.withAlpha((0.1 * 255).round()),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, '/$route');
        }
      },
    );
  }
}
