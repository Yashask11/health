import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  /// 🔹 Initialize FCM + local notifications
  Future<void> _initNotifications() async {
    await _messaging.requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // When tapped from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification tapped: ${message.notification?.title}');
    });
  }

  /// 🔹 Show notification using flutter_local_notifications
  Future<void> _showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'health_channel',
      'Health Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message!',
      notifDetails,
    );

    debugPrint('✅ Local notification displayed');
  }

  /// 🔹 Get Firestore notifications (for both donor and receiver)
  Stream<QuerySnapshot> _getNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
      Filter.or(
        Filter('donorUid', isEqualTo: currentUser.uid),
        Filter('receiverUid', isEqualTo: currentUser.uid),
      ),
    )
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data =
                  notifications[index].data() as Map<String, dynamic>? ?? {};

              final title = data['title'] ?? 'New Notification';
              final message = data['message'] ?? '';
              final time = data['timestamp'] is Timestamp
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now();

              final isForDonor = data['donorUid'] ==
                  FirebaseAuth.instance.currentUser?.uid;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(
                    isForDonor
                        ? Icons.volunteer_activism
                        : Icons.inventory_2_outlined,
                    color: isForDonor ? Colors.orange : Colors.green,
                    size: 28,
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
