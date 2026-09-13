import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      // Lock to the detected timezone
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("NotificationService: Timezone locked to $timeZoneName");
    } catch (e) {
      print("NotificationService: Timezone error: $e");
      // Fallback to UTC if detection fails (rare)
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("NotificationService: Tapped ID ${details.payload}");
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminders_channel_v3', // Incremented version to clear previous issues
      'Reminders',
      description: 'Scheduled task reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // 1. Direct conversion from local DateTime to Timezone DateTime
      var scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      print("NotificationService: Scheduling...");
      print("NotificationService: Current Time: $now");
      print("NotificationService: Target Time: $scheduledDate");

      // 2. Safety Buffer: If the time is in the past or within 10 seconds, 
      // push it forward to 15 seconds from now.
      if (scheduledDate.isBefore(now.add(const Duration(seconds: 10)))) {
        scheduledDate = now.add(const Duration(seconds: 15));
        print("NotificationService: Time too close/past. Pushed to: $scheduledDate");
      }

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      bool canScheduleExact = false;
      if (androidImplementation != null) {
        canScheduleExact = await androidImplementation.canScheduleExactNotifications() ?? false;
      }

      // 3. Perform the schedule
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel_v3',
            'Reminders',
            channelDescription: 'Scheduled task reminders',
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'ticker',
            color: Color(0xFFD4B483),
            // Removed fullScreenIntent and category to match showImmediateNotification more closely
            visibility: NotificationVisibility.public,
          ),
        ),
        // Try inexact mode first as it is more likely to be permitted by the OS without extra user intervention
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: id.toString(),
      );
      print("NotificationService: SCHEDULE SUCCESS for ID $id");
    } catch (e) {
      print("NotificationService: SCHEDULE FAILED - $e");
    }
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders_channel_v3',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _notifications.show(id, title, body, details);
  }
}
