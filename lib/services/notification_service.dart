import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String title,
    required String message,
    required String donorUid,
    required String receiverUid,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'donorUid': donorUid,
      'receiverUid': receiverUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}