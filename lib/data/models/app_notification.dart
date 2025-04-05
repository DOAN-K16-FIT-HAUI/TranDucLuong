import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotification.fromRemoteMessage(Map<String, dynamic> message) {
    final notification = message['notification'] as Map<String, dynamic>?;
    final data = message['data'] as Map<String, dynamic>? ?? message;
    debugPrint('Message received: $message'); // In dữ liệu để kiểm tra
    return AppNotification(
      id: message['messageId'] ?? DateTime.now().toIso8601String(),
      title: notification?['title'] ?? data['title'] ?? 'No Title',
      body: notification?['body'] ?? data['body'] ?? 'No Body',
      timestamp: DateTime.now(),
    );
  }
}
