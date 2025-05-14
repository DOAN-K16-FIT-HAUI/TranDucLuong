

enum NotificationType { cloud, local }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type = NotificationType.cloud,
    this.data,
  });

  AppNotification copyWith({bool? isRead, Map<String, dynamic>? data}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      data: data ?? this.data,
    );
  }

  factory AppNotification.fromRemoteMessage(Map<String, dynamic> message) {
    final notification = message['notification'] as Map<String, dynamic>?;
    final data = message['data'] as Map<String, dynamic>? ?? message;
    
    // Ensure we have a unique and consistent ID for the notification
    final String id = message['messageId'] ?? 
        (data['id'] != null ? data['id'].toString() : DateTime.now().microsecondsSinceEpoch.toString());
    
    return AppNotification(
      id: id,
      title: notification?['title'] ?? data['title'] ?? 'No Title',
      body: notification?['body'] ?? data['body'] ?? 'No Body',
      timestamp: DateTime.now(),
      type: NotificationType.cloud,
      data: data,
    );
  }

  factory AppNotification.local({
    required String title,
    required String body,
    String? payload,
  }) {
    // Create a more unique ID using microseconds (more granular than milliseconds)
    final String id = '${DateTime.now().microsecondsSinceEpoch}_${title.hashCode}';
    
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: NotificationType.local,
      data: payload != null ? {'payload': payload} : null,
    );
  }

  factory AppNotification.savingsReminder(String message) {
    return AppNotification.local(
      title: 'Savings Reminder',
      body: message,
      payload: 'savings_reminder',
    );
  }

  factory AppNotification.spendingAlert(String message) {
    return AppNotification.local(
      title: 'Spending Alert',
      body: message,
      payload: 'spending_alert',
    );
  }
}
