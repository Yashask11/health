import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  // ✅ Correct order → (Map data, String id)
  factory AppNotification.fromMap(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Optional: If you ever need to upload notifications
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}