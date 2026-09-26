import 'package:flutter/material.dart';
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

  static const String _channelId = 'reminders_channel_v3';
  static const String _channelName = 'Reminders';
  static const String _channelDesc = 'Scheduled task reminders';

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint("NotificationService: Timezone locked to $timeZoneName");
      } catch (e) {
        debugPrint("NotificationService: Specific timezone lookup failed ($e), searching fallback...");
        final offset = DateTime.now().timeZoneOffset;
        final matchingLocation = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == offset.inMilliseconds,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(matchingLocation);
        debugPrint("NotificationService: Fallback timezone locked to ${matchingLocation.name}");
      }
    } catch (e) {
      debugPrint("NotificationService: Timezone error: $e");
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
        debugPrint("NotificationService: Tapped notification payload: ${details.payload}");
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
      // 1. Construct TZDateTime using tz.local components to avoid any offset issues
      var scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
        scheduledTime.second,
      );
      final now = tz.TZDateTime.now(tz.local);

      debugPrint("NotificationService: Scheduling reminder ID $id");
      debugPrint("NotificationService: Current Time: $now");
      debugPrint("NotificationService: Target Time: $scheduledDate");

      // 2. Past-time check
      if (scheduledDate.isBefore(now)) {
        // If it was scheduled for right now / a few seconds ago due to picker delay, push slightly ahead
        if (now.difference(scheduledDate).inSeconds <= 30) {
          scheduledDate = now.add(const Duration(seconds: 2));
          debugPrint("NotificationService: Scheduled time just elapsed, adjusted to: $scheduledDate");
        } else {
          debugPrint("NotificationService: Target time $scheduledDate is in the past compared to $now, skipping schedule.");
          return;
        }
      }

      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      bool canScheduleExact = true;
      if (androidImplementation != null) {
        canScheduleExact = await androidImplementation.canScheduleExactNotifications() ?? true;
        if (!canScheduleExact) {
          await androidImplementation.requestExactAlarmsPermission();
          canScheduleExact = await androidImplementation.canScheduleExactNotifications() ?? true;
        }
      }

      final AndroidScheduleMode scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      // 3. Perform zoned schedule
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'ticker',
            color: Color(0xFFD4B483),
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        payload: id.toString(),
      );
      debugPrint("NotificationService: SCHEDULE SUCCESS for ID $id at $scheduledDate (mode: $scheduleMode)");
    } catch (e) {
      debugPrint("NotificationService: SCHEDULE FAILED - $e");
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
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _notifications.show(id, title, body, details);
  }
}
