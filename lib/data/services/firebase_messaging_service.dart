import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Khởi tạo service và yêu cầu quyền thông báo
  Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // Lấy FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Xử lý thông báo nền
  static Future<void> backgroundHandler(RemoteMessage message) async {
    debugPrint('Background message: ${message.messageId}');
  }

  // Lắng nghe thông báo foreground
  void onForegroundMessage(Function(RemoteMessage) callback) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      callback(message);
    });
  }

  // Lắng nghe khi nhấn thông báo từ background
  void onMessageOpenedApp(VoidCallback callback) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.notification?.title}');
      callback();
    });
  }

  // Kiểm tra thông báo khi mở ứng dụng từ trạng thái terminated
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }
}