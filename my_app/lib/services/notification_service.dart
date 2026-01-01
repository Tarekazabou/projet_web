import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      AppLogger.success('Notification service initialized', tag: 'Notifications');
    } catch (e) {
      AppLogger.error('Failed to initialize notifications', tag: 'Notifications', error: e);
    }
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? true; // Android doesn't need explicit permission in most cases
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}', tag: 'Notifications');
    // Handle navigation based on payload
  }

  /// Show a notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mealy_channel',
      'Mealy Notifications',
      channelDescription: 'Notifications for nutrition, hydration, and meal reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(id, title, body, details, payload: payload);
      AppLogger.info('Notification shown: $title', tag: 'Notifications');
    } catch (e) {
      AppLogger.error('Failed to show notification', tag: 'Notifications', error: e);
    }
  }

  /// Schedule a daily notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mealy_daily_channel',
          'Daily Reminders',
          channelDescription: 'Daily reminders for nutrition and hydration',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    AppLogger.info('Scheduled daily notification: $title at $hour:$minute', tag: 'Notifications');
  }

  /// Calculate next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    AppLogger.info('Cancelled notification: $id', tag: 'Notifications');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.info('Cancelled all notifications', tag: 'Notifications');
  }

  // Predefined notification IDs
  static const int nutritionReminderId = 1;
  static const int hydrationReminderId = 2;
  static const int shoppingReminderId = 3;
  static const int expiringItemsReminderId = 4;

  /// Schedule nutrition reminder
  Future<void> scheduleNutritionReminder({int hour = 12, int minute = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('nutrition_reminder_enabled') ?? true;
    
    if (enabled) {
      await scheduleDailyNotification(
        id: nutritionReminderId,
        title: '🍽️ Time to log your meal!',
        body: 'Don\'t forget to track your nutrition for today',
        hour: hour,
        minute: minute,
        payload: 'nutrition',
      );
    }
  }

  /// Schedule hydration reminder
  Future<void> scheduleHydrationReminder({int hour = 10, int minute = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('hydration_reminder_enabled') ?? true;
    
    if (enabled) {
      await scheduleDailyNotification(
        id: hydrationReminderId,
        title: '💧 Stay hydrated!',
        body: 'Remember to drink water throughout the day',
        hour: hour,
        minute: minute,
        payload: 'hydration',
      );
    }
  }

  /// Schedule shopping reminder
  Future<void> scheduleShoppingReminder({int hour = 18, int minute = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('shopping_reminder_enabled') ?? true;
    
    if (enabled) {
      await scheduleDailyNotification(
        id: shoppingReminderId,
        title: '🛒 Check your shopping list!',
        body: 'Review your shopping list and plan your grocery trip',
        hour: hour,
        minute: minute,
        payload: 'shopping',
      );
    }
  }

  /// Show expiring items notification
  Future<void> showExpiringItemsNotification(int itemCount) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('expiring_items_reminder_enabled') ?? true;
    
    if (enabled && itemCount > 0) {
      await showNotification(
        id: expiringItemsReminderId,
        title: '⚠️ Items expiring soon!',
        body: 'You have $itemCount item${itemCount > 1 ? 's' : ''} expiring soon in your fridge',
        payload: 'fridge',
      );
    }
  }

  /// Setup all default reminders
  Future<void> setupDefaultReminders() async {
    await scheduleNutritionReminder(hour: 12, minute: 0);
    await scheduleHydrationReminder(hour: 10, minute: 0);
    await scheduleShoppingReminder(hour: 18, minute: 0);
    
    AppLogger.success('Default reminders setup complete', tag: 'Notifications');
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nutrition_reminder_enabled': prefs.getBool('nutrition_reminder_enabled') ?? true,
      'hydration_reminder_enabled': prefs.getBool('hydration_reminder_enabled') ?? true,
      'shopping_reminder_enabled': prefs.getBool('shopping_reminder_enabled') ?? true,
      'expiring_items_reminder_enabled': prefs.getBool('expiring_items_reminder_enabled') ?? true,
    };
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Reschedule or cancel based on new setting
    if (key == 'nutrition_reminder_enabled') {
      if (value) {
        await scheduleNutritionReminder();
      } else {
        await cancelNotification(nutritionReminderId);
      }
    } else if (key == 'hydration_reminder_enabled') {
      if (value) {
        await scheduleHydrationReminder();
      } else {
        await cancelNotification(hydrationReminderId);
      }
    } else if (key == 'shopping_reminder_enabled') {
      if (value) {
        await scheduleShoppingReminder();
      } else {
        await cancelNotification(shoppingReminderId);
      }
    }
    
    AppLogger.info('Updated notification setting: $key = $value', tag: 'Notifications');
  }
}
