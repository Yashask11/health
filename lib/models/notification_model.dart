import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String donorUid;
  final String title;
  final String message;
  final Timestamp timestamp;

  AppNotification({
    required this.id,
    required this.donorUid,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      donorUid: data['donorUid'] ?? '',
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp']
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorUid': donorUid,
      'title': title,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
