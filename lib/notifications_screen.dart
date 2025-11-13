import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _listenForUnreadCount();
  }

  Future<void> _initNotifications() async {
    await _messaging.requestPermission();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);
  }

  Stream<QuerySnapshot> _getNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _listenForUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() => _unreadCount = snapshot.docs.length);
    });
  }

  Future<Map<String, String>> _getUserDetails(String uid) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return {'phone': '', 'address': ''};

      final data = doc.data()!;
      final phone = data['phone']?.toString() ?? '';

      String address = "";
      if (data['address'] != null && data['address'] is Map) {
        final a = Map<String, dynamic>.from(data['address']);
        address = [
          a['street'],
          a['city'],
          a['state'],
          a['pincode']
        ]
            .where((v) => v != null && v.toString().trim().isNotEmpty)
            .join(", ");
      }

      return {'phone': phone, 'address': address};
    } catch (e) {
      return {'phone': '', 'address': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index].data() as Map<String, dynamic>;

              final title = notif['title'] ?? '';
              final message = notif['message'] ?? '';
              final requestId = notif['requestId'] ?? '';

              final timestamp = notif['timestamp'] as Timestamp?;
              final date = timestamp?.toDate() ?? DateTime.now();
              final formattedTime =
                  "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2,'0')}";

              final isRead = notif['isRead'] ?? false;

              return Card(
                color: isRead ? Colors.white : Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.blue),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      const SizedBox(height: 4),
                      Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),

                  onTap: () async {
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notifications[index].id)
                        .update({'isRead': true});

                    final requestDoc = await FirebaseFirestore.instance
                        .collection("requests")
                        .doc(requestId)
                        .get();

                    if (!requestDoc.exists) return;

                    final receiverUid = requestDoc.data()?['receiverUid'] ?? '';

                    final receiverData = await _getUserDetails(receiverUid);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailScreen(
                          donorPhone: receiverData['phone']!,     // ★ FIX: green text shows receiver phone
                          receiverPhone: receiverData['phone']!,
                          receiverAddress: receiverData['address']!,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}