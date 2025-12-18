// lib/models/appointment_entry.dart

import 'package:hive/hive.dart';

part 'appointment_entry.g.dart';

@HiveType(typeId: 4)
class AppointmentEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  bool notifyOneDay;

  @HiveField(5)
  bool notifyOneWeek;

  @HiveField(6)
  int? oneDayNotificationId;

  @HiveField(7)
  int? oneWeekNotificationId;

  @HiveField(8)
  String? linkedScoreId; // Link to ScoreEntry ID

  @HiveField(9)
  bool isScoreEntry; // Flag to identify score-generated appointments

  AppointmentEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.notifyOneDay = false,
    this.notifyOneWeek = false,
    this.oneDayNotificationId,
    this.oneWeekNotificationId,
    this.linkedScoreId,
    this.isScoreEntry = false,
  });

  // Helper to check if appointment is on a specific day
  bool isOnDay(DateTime day) {
    return dateTime.year == day.year &&
        dateTime.month == day.month &&
        dateTime.day == day.day;
  }

  // Helper to format time
  String get timeString {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
