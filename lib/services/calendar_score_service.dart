// lib/services/calendar_score_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment_entry.dart';
import '../models/score_entry.dart';

class CalendarScoreService {
  static final CalendarScoreService _instance = CalendarScoreService
      ._internal();

  factory CalendarScoreService() => _instance;

  CalendarScoreService._internal();

  /// Create or update a calendar entry for a score
  Future<void> createOrUpdateScoreAppointment(ScoreEntry scoreEntry) async {
    final appointmentsBox = Hive.box<AppointmentEntry>('appointments');

    // Check if an appointment already exists for this score
    AppointmentEntry? existingAppointment;
    try {
      existingAppointment = appointmentsBox.values.firstWhere(
            (appointment) => appointment.linkedScoreId == scoreEntry.id,
      );
    } catch (e) {
      // No existing appointment found
    }

    final title = 'Score of ${scoreEntry.score} Recorded';
    final description = '${scoreEntry.practice} - ${scoreEntry.caliber}\n'
        'Firearm: ${scoreEntry.firearmId}';

    if (existingAppointment != null) {
      // Update existing appointment
      existingAppointment.title = title;
      existingAppointment.description = description;
      existingAppointment.dateTime = scoreEntry.date;
      await existingAppointment.save();
    } else {
      // Create new appointment
      final newAppointment = AppointmentEntry(
        id: const Uuid().v4(),
        title: title,
        description: description,
        dateTime: scoreEntry.date,
        linkedScoreId: scoreEntry.id,
        isScoreEntry: true,
        notifyOneDay: false,
        notifyOneWeek: false,
      );
      await appointmentsBox.add(newAppointment);
    }
  }

  /// Delete calendar entry when score is deleted
  Future<void> deleteScoreAppointment(String scoreId) async {
    final appointmentsBox = Hive.box<AppointmentEntry>('appointments');

    // Find and delete the linked appointment
    try {
      final appointment = appointmentsBox.values.firstWhere(
            (appointment) => appointment.linkedScoreId == scoreId,
      );
      await appointment.delete();
    } catch (e) {
      // No appointment found for this score
    }
  }

  /// Get the score entry linked to an appointment
  ScoreEntry? getLinkedScore(AppointmentEntry appointment) {
    if (appointment.linkedScoreId == null) return null;

    final scoresBox = Hive.box<ScoreEntry>('scores');
    try {
      return scoresBox.values.firstWhere(
            (score) => score.id == appointment.linkedScoreId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if appointment is linked to a score
  bool isScoreLinked(AppointmentEntry appointment) {
    return appointment.isScoreEntry && appointment.linkedScoreId != null;
  }
}
