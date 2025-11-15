import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String donorUid;
  final String receiverUid;     // ✅ added
  final String title;
  final String message;
  final Timestamp timestamp;
  final bool isRead;            // ✅ added

  AppNotification({
    required this.id,
    required this.donorUid,
    required this.receiverUid,   // ✅ added
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,        // ✅ added
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      donorUid: data['donorUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',     // ✅ added
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp']
          : Timestamp.now(),
      isRead: data['isRead'] ?? false,            // ✅ added
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorUid': donorUid,
      'receiverUid': receiverUid,   // ✅ added
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,             // ✅ added
    };
  }
}
