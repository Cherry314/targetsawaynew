// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/appointment_entry.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _requestIOSPermissions();

    _initialized = true;
  }

  Future<void> _requestIOSPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // You can navigate to specific appointment here
  }

  // Schedule notifications for an appointment
  Future<Map<String, int>> scheduleAppointmentNotifications({
    required AppointmentEntry appointment,
  }) async {
    final Map<String, int> notificationIds = {};

    // Generate unique notification IDs
    final oneDayId = DateTime
        .now()
        .millisecondsSinceEpoch % 100000000;
    final oneWeekId = (DateTime
        .now()
        .millisecondsSinceEpoch + 1) % 100000000;

    if (appointment.notifyOneDay) {
      final scheduledDate = appointment.dateTime.subtract(
          const Duration(days: 1));
      if (scheduledDate.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: oneDayId,
          title: 'Appointment Tomorrow',
          body: '${appointment.title} at ${appointment.timeString}',
          scheduledDate: scheduledDate,
        );
        notificationIds['oneDay'] = oneDayId;
      }
    }

    if (appointment.notifyOneWeek) {
      final scheduledDate = appointment.dateTime.subtract(
          const Duration(days: 7));
      if (scheduledDate.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: oneWeekId,
          title: 'Appointment in 1 Week',
          body: '${appointment.title} on ${_formatDate(
              appointment.dateTime)} at ${appointment.timeString}',
          scheduledDate: scheduledDate,
        );
        notificationIds['oneWeek'] = oneWeekId;
      }
    }

    return notificationIds;
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'appointments_channel',
        'Appointments',
        channelDescription: 'Notifications for upcoming appointments',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Error scheduling notification - silently fail
      // In production, you might want to log this to a crash reporting service
    }
  }

  // Cancel specific notifications
  Future<void> cancelNotifications({
    int? oneDayNotificationId,
    int? oneWeekNotificationId,
  }) async {
    if (oneDayNotificationId != null) {
      await _notificationsPlugin.cancel(oneDayNotificationId);
    }
    if (oneWeekNotificationId != null) {
      await _notificationsPlugin.cancel(oneWeekNotificationId);
    }
  }

  // Cancel all notifications for debugging
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
