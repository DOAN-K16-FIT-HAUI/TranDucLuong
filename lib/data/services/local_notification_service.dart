import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

class LocalNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotificationClick = ValueNotifier<String?>(null);

  // Define consistent notification IDs to avoid conflicts
  static const int savingsReminderNotificationId = 0;
  static const int spendingAlertNotificationId = 1;
  static const int testNotificationId = 999;

  // Channel IDs
  static const String savingsReminderChannelId = 'savings_reminder_channel';
  static const String generalChannelId = 'general_channel';
  static const String alertChannelId = 'alert_channel';

  static Future<void> initialize() async {
    if (kIsWeb) {
      return; // Không hỗ trợ web
    }

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked with payload: ${details.payload}');
        onNotificationClick.value = details.payload;
      },
    );

    // Luôn yêu cầu quyền thông báo khi khởi tạo
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    try {
      // Kiểm tra và yêu cầu quyền trên Android
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.areNotificationsEnabled();
        debugPrint('Android notification permission status: $granted');
      }

      // Yêu cầu quyền trên iOS
      final IOSFlutterLocalNotificationsPlugin? iOSImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iOSImplementation != null) {
        final bool? result = await iOSImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
        debugPrint('iOS notification permission granted: $result');
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  // Schedule daily savings reminder with permission check
  static Future<void> scheduleDailySavingsReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    // Check notification permission before scheduling
    final bool hasPermission = await checkPermissionStatus();
    if (!hasPermission) {
      debugPrint('No notification permission granted');
      throw Exception('Notification permission not granted');
    }

    // Only cancel savings reminder notifications (not all notifications)
    await _notifications.cancel(savingsReminderNotificationId);

    try {
      final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);

      debugPrint('Scheduling reminder for: ${scheduledTime.toString()}');

      await _notifications.zonedSchedule(
        savingsReminderNotificationId, // Use fixed ID for savings reminder
        title,
        body,
        scheduledTime,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            savingsReminderChannelId,
            'Savings Reminders',
            channelDescription: 'Daily reminders to save money',
            importance: Importance.max,
            priority: Priority.max,
            enableLights: true,
            enableVibration: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'savings_reminder',
      );

      // Thử gửi một thông báo ngay lập tức để kiểm tra quyền
      await showNotification(
        id: testNotificationId,
        title: 'Reminder Settings Saved',
        body:
            'Your daily reminder has been set for $hour:${minute.toString().padLeft(2, '0')}',
        payload: 'test_notification',
      );

      debugPrint('Daily savings reminder scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
      rethrow;
    }
  }

  // Cancel specific notification by ID
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;

    try {
      await _notifications.cancel(id);
      debugPrint('Notification with ID $id cancelled');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;

    try {
      await _notifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  // Get next instance of specified time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    debugPrint('Current time: ${now.toString()}');

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('Scheduling for tomorrow: ${scheduledDate.toString()}');
    } else {
      debugPrint('Scheduling for today: ${scheduledDate.toString()}');
    }

    return scheduledDate;
  }

  // Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            generalChannelId,
            'General Notifications',
            channelDescription: 'For general app notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('Immediate notification shown: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Kiểm tra thông báo đã lên lịch
  static Future<bool> checkPendingNotificationRequests() async {
    if (kIsWeb) return false;

    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _notifications.pendingNotificationRequests();

      debugPrint(
        'Number of pending notifications: ${pendingNotifications.length}',
      );

      for (var notification in pendingNotifications) {
        debugPrint(
          'Pending notification: ID=${notification.id}, Title=${notification.title}, Body=${notification.body}',
        );
      }

      return pendingNotifications.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending notifications: $e');
      return false;
    }
  }

  // Kiểm tra xem ứng dụng có quyền gửi thông báo hay không
  static Future<bool> checkPermissionStatus() async {
    if (kIsWeb) return false;

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.areNotificationsEnabled();
        debugPrint('Android notification permission status: $granted');
        return granted ?? false;
      }

      // For iOS, assume permission is granted if the plugin is initialized
      final IOSFlutterLocalNotificationsPlugin? iOSImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iOSImplementation != null) {
        return true; // We can't check iOS permission status after initialization
      }

      return false;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Helper method to show a user-friendly error notification
  static Future<void> showErrorNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    try {
      await showNotification(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        payload: 'error_notification',
      );
    } catch (e) {
      // Just log if we can't even show error notifications
      debugPrint('Failed to show error notification: $e');
    }
  }

  // Check network connectivity with fallback
  static Future<bool> checkConnectivity() async {
    try {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      } on MissingPluginException catch (e) {
        // Plugin not initialized properly, log and assume connectivity exists
        debugPrint('Connectivity plugin not available: $e');
        return true; // Assume connectivity to allow operations to continue
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return true; // Default to assuming connectivity in case of errors
    }
  }
}
