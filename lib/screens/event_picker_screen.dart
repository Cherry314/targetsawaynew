import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/hive/event.dart';
import '../widgets/app_drawer.dart';
import '../main.dart';
import 'event_detail_screen.dart';

class EventPickerScreen extends StatefulWidget {
  const EventPickerScreen({super.key});

  @override
  State<EventPickerScreen> createState() => _EventPickerScreenState();
}

class _EventPickerScreenState extends State<EventPickerScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventBox = Hive.box<Event>('events');
    final allEvents = eventBox.values.toList();

    // Filter events based on search query
    final filteredEvents = _searchQuery.isEmpty
        ? allEvents
        : allEvents.where((event) {
            final searchLower = _searchQuery.toLowerCase();
            final nameMatch = event.name.toLowerCase().contains(searchLower);
            final numberMatch = event.eventNumber.toString().contains(searchLower);
            return nameMatch || numberMatch;
          }).toList();

    // Sort events by event number
    filteredEvents.sort((a, b) => a.eventNumber.compareTo(b.eventNumber));

    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        drawer: const AppDrawer(currentRoute: 'event_picker'),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Event Browser',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search events by name or number...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              // Results count
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Found ${filteredEvents.length} event${filteredEvents.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // Event Cards List
              Expanded(
                child: filteredEvents.isEmpty
                    ? _buildEmptyState(isDark, primaryColor)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return _buildEventCard(
                            context,
                            event,
                            primaryColor,
                            isDark,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'No events available'
                : 'Try adjusting your search',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Event event,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(
                  event: event,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Event number badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${event.eventNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.applicableFirearmIds.length} firearm option${event.applicableFirearmIds.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
