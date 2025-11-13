import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_detail_screen.dart';
import 'confirm_request_screen.dart';   // ⭐ NEW SCREEN IMPORT

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  int _unreadCountDonor = 0;
  int _unreadCountReceiver = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initNotifications();
    _listenForUnreadCounts();
  }

  Future<void> _initNotifications() async {
    await _messaging.requestPermission();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);
  }

  // ⭐ STREAM FOR DONOR NOTIFICATIONS
  Stream<QuerySnapshot> _donorNotifications() {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: current.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ⭐ STREAM FOR RECEIVER NOTIFICATIONS
  Stream<QuerySnapshot> _receiverNotifications() {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('fromUid', isEqualTo: current.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ⭐ COUNT UNREAD FOR BOTH
  void _listenForUnreadCounts() {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: current.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      setState(() => _unreadCountDonor = snap.docs.length);
    });

    FirebaseFirestore.instance
        .collection('notifications')
        .where('fromUid', isEqualTo: current.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      setState(() => _unreadCountReceiver = snap.docs.length);
    });
  }

  // ⭐ FETCH USER DETAILS
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

  // ⭐ REUSABLE NOTIFICATION LIST
  Widget _buildNotificationList(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifs = snapshot.data!.docs;
        if (notifs.isEmpty) {
          return const Center(child: Text("No notifications yet."));
        }

        return ListView.builder(
          itemCount: notifs.length,
          itemBuilder: (context, index) {
            final notif = notifs[index].data() as Map<String, dynamic>;

            final title = notif['title'] ?? '';
            final message = notif['message'] ?? '';
            final requestId = notif['requestId'] ?? '';

            final timestamp = notif['timestamp'] as Timestamp?;
            final date = timestamp?.toDate() ?? DateTime.now();
            final formattedTime =
                "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

            final isRead = notif['isRead'] ?? false;

            return Card(
              color: isRead ? Colors.white : Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.notifications_active,
                    color: Colors.blue),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () async {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notifs[index].id)
                      .update({'isRead': true});

                  // ⭐ If receiver → open ConfirmRequestScreen
                  final currentUid = FirebaseAuth.instance.currentUser?.uid;
                  if (notif['fromUid'] == currentUid) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConfirmRequestScreen(requestId: requestId),
                      ),
                    );
                    return;
                  }

                  // ⭐ DONOR → existing behavior
                  final reqDoc = await FirebaseFirestore.instance
                      .collection("requests")
                      .doc(requestId)
                      .get();

                  if (!reqDoc.exists) return;

                  final receiverUid = reqDoc['receiverUid'] ?? '';
                  final receiverData = await _getUserDetails(receiverUid);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailScreen(
                        donorPhone: receiverData['phone']!,
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
    );
  }

  // UI -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: "Donor (${_unreadCountDonor})"),
            Tab(text: "Receiver (${_unreadCountReceiver})"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_donorNotifications()),
          _buildNotificationList(_receiverNotifications()),
        ],
      ),
    );
  }
}
