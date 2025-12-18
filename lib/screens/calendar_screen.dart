// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../models/appointment_entry.dart';
import '../widgets/appointment_dialog.dart';
import '../main.dart';
import '../services/calendar_score_service.dart';
import '../models/score_entry.dart';
import 'dart:io';
import '../utils/date_utils.dart';
import 'enter_score_screen.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<AppointmentEntry> _getAppointmentsForDay(DateTime day) {
    final box = Hive.box<AppointmentEntry>('appointments');
    return box.values.where((appointment) => appointment.isOnDay(day)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void _showAppointmentDialog({AppointmentEntry? appointment}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AppointmentDialog(
            selectedDate: _selectedDay,
            appointment: appointment,
          ),
    );

    if (result == true) {
      setState(() {}); // Refresh the calendar
    }
  }

  void _openScoreEntryScreen() async {
    // Create a temporary ScoreEntry with the selected date to pass to EnterScoreScreen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EnterScoreScreen(
              editEntry: ScoreEntry(
                id: '',
                // Temporary ID
                date: _selectedDay,
                score: 0,
                practice: '',
                caliber: '',
                firearmId: '',
                comp: false,
                targetCaptured: false,
              ),
              openedFromCalendar: true, // Flag to return to calendar after save
            ),
      ),
    );
    setState(() {}); // Refresh when returning
  }

  void _showScoreDetail(AppointmentEntry appointment) {
    final score = CalendarScoreService().getLinkedScore(appointment);
    if (score == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Scaffold(
              appBar: AppBar(
                title: Text(formatUKDate(score.date)),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Score:', score.score.toString()),
                        _buildDetailRow('Practice:', score.practice),
                        _buildDetailRow('Calibre:', score.caliber),
                        _buildDetailRow('Firearm ID:', score.firearmId),
                        if (score.firearm != null && score.firearm!.isNotEmpty)
                          _buildDetailRow('Firearm:', score.firearm!),
                        if (score.notes != null && score.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(score.notes!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (score.targetFilePath != null &&
                      File(score.targetFilePath!).existsSync())
                    Expanded(
                      child: Center(
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Image.file(
                            File(score.targetFilePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(
                        child: Text('No target image available'),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

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
          drawer: const AppDrawer(currentRoute: 'calendar'),
          appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
          const HelpIconButton(
            title: 'Calendar Help',
            content: HelpContent.calendarScreen,
            iconColor: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Calendar widget
            ValueListenableBuilder(
              valueListenable: Hive
                  .box<AppointmentEntry>('appointments')
                  .listenable(),
              builder: (context, Box<AppointmentEntry> box, _) {
                return TableCalendar(
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2100, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) {
                    return _getAppointmentsForDay(day);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: primaryColor.withAlpha((0.3 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronIcon: Icon(
                        Icons.chevron_left, color: primaryColor),
                    rightChevronIcon: Icon(
                        Icons.chevron_right, color: primaryColor),
                    titleTextStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    weekendStyle: TextStyle(
                      color: primaryColor,
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 1),

            // Selected day header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatSelectedDay(_selectedDay),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAppointmentDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),

            // Appointments list for selected day
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive
                    .box<AppointmentEntry>('appointments')
                    .listenable(),
                builder: (context, Box<AppointmentEntry> box, _) {
                  final appointments = _getAppointmentsForDay(_selectedDay);

                  if (appointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No appointments',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _showAppointmentDialog(),
                            child: const Text('Add Appointment'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: appointments.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final isScoreEntry = CalendarScoreService().isScoreLinked(
                          appointment);

                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isScoreEntry
                                  ? Colors.green.withAlpha((0.2 * 255).round())
                                  : primaryColor.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: isScoreEntry
                                  ? Icon(
                                Icons.gps_fixed,
                                color: Colors.green,
                                size: 24,
                              )
                                  : Text(
                                appointment.timeString,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          title: Text(
                            appointment.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (appointment.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(appointment.description),
                                ),
                              if (appointment.notifyOneDay ||
                                  appointment.notifyOneWeek)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getNotificationText(appointment),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (isScoreEntry) {
                              _showScoreDetail(appointment);
                            } else {
                              _showAppointmentDialog(appointment: appointment);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Target icon button - Bottom Left
          Positioned(
            left: 30,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: 'enterScore',
              // Unique tag to avoid hero animation conflicts
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              onPressed: _openScoreEntryScreen,
              tooltip: 'Enter Score',
              child: const Icon(Icons.gps_fixed),
            ),
          ),
          // Add appointment button - Bottom Right (default position)
          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: 'addAppointment',
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              onPressed: () => _showAppointmentDialog(),
              tooltip: 'Add Appointment',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  String _formatSelectedDay(DateTime day) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }

  String _getNotificationText(AppointmentEntry appointment) {
    if (appointment.notifyOneDay && appointment.notifyOneWeek) {
      return '1 day & 1 week before';
    } else if (appointment.notifyOneDay) {
      return '1 day before';
    } else if (appointment.notifyOneWeek) {
      return '1 week before';
    }
    return '';
  }
}
