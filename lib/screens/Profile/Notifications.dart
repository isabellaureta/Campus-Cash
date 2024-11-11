import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationHelper() {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(android: androidSettings, iOS: iOSSettings);
    _notificationsPlugin.initialize(settings);
  }

  Future<void> scheduleNotification(String frequency, TimeOfDay time, int? day) async {
    await _notificationsPlugin.cancelAll(); // Clear existing notifications

    final scheduledTime = _calculateScheduledTime(time, frequency, day);

    if (scheduledTime == null) return; // If there's an error in scheduling

    await _notificationsPlugin.zonedSchedule(
      0,
      '${frequency} Reminder',
      'It’s time for your $frequency reminder!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_id',
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getDateTimeComponent(frequency),
    );
  }

  tz.TZDateTime _calculateScheduledTime(TimeOfDay time, String frequency, int? day) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1)); // Next day if time has passed
    }

    if (frequency == 'Weekly' && day != null) {
      while (scheduledTime.weekday != day) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }
    } else if (frequency == 'Monthly' && day != null) {
      while (scheduledTime.day != day) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }
    }
    return scheduledTime;
  }

  DateTimeComponents _getDateTimeComponent(String frequency) {
    switch (frequency) {
      case 'Weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'Monthly':
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return DateTimeComponents.time;
    }
  }

  Future<void> cancelNotification() async {
    await _notificationsPlugin.cancelAll();
  }
}
