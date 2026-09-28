import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminders_channel_v4';
  static const String _channelName = 'Reminders';
  static const String _channelDesc = 'Scheduled task and app reminders';

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint("NotificationService: Timezone set to $timeZoneName");
      } catch (e) {
        debugPrint("NotificationService: Specific timezone failed ($e), using local fallback");
        final offset = DateTime.now().timeZoneOffset;
        final matchingLocation = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(matchingLocation);
      }
    } catch (e) {
      debugPrint("NotificationService: Timezone init error: $e");
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("NotificationService: Notification tapped payload: ${details.payload}");
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'Sorted Reminder',
        color: Color(0xFFD4B483),
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      debugPrint("NotificationService: Scheduling reminder ID $id for $scheduledDate (now: $now)");

      if (scheduledDate.isBefore(now)) {
        if (now.difference(scheduledDate).inSeconds <= 30) {
          final adjustedDate = now.add(const Duration(seconds: 2));
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            adjustedDate,
            _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            payload: id.toString(),
          );
          debugPrint("NotificationService: Adjusted & scheduled ID $id");
        } else {
          debugPrint("NotificationService: Target time $scheduledDate is in the past, skipping.");
        }
        return;
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: id.toString(),
      );
      debugPrint("NotificationService: SCHEDULE SUCCESS for ID $id at $scheduledDate");
    } catch (e) {
      debugPrint("NotificationService: AlarmClock scheduling error: $e, trying exactAllowWhileIdle...");
      try {
        final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: id.toString(),
        );
      } catch (e2) {
        debugPrint("NotificationService: Fallback scheduling failed: $e2");
      }
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
    await _notifications.show(id, title, body, _notificationDetails());
  }
}
