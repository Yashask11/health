import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_detail_screen.dart';
import 'confirm_request_screen.dart';

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

  late TabController _tabController;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initNotifications();
    _listenForUnreadCount();
  }

  Future<void> _initNotifications() async {
    await _messaging.requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);
  }

  /// RECEIVER NOTIFICATIONS → only "Request Submitted"
  Stream<QuerySnapshot> _receiverNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("notifications")
        .where("toUid", isEqualTo: user.uid)
        .where("title", isEqualTo: "Request Submitted")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// DONOR NOTIFICATIONS → New Donation Request + Request Confirmed
  Stream<QuerySnapshot> _donorNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("notifications")
        .where("toUid", isEqualTo: user.uid)
        .where("title", whereIn: [
      "New Donation Request",
      "Request Confirmed",
    ])
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  void _listenForUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      setState(() => _unreadCount = snap.docs.length);
    });
  }

  Future<Map<String, String>> _getUserDetails(String uid) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) return {"phone": "", "address": ""};

      final data = doc.data()!;
      final phone = data["phone"]?.toString() ?? "";

      String address = "";
      if (data["address"] != null && data["address"] is Map) {
        final a = Map<String, dynamic>.from(data["address"]);
        address = [
          a["street"],
          a["city"],
          a["state"],
          a["pincode"],
        ].where((v) => v != null && v.toString().trim().isNotEmpty).join(", ");
      }

      return {"phone": phone, "address": address};
    } catch (e) {
      return {"phone": "", "address": ""};
    }
  }

  Widget _buildNotificationList(
      Stream<QuerySnapshot> stream, bool isReceiverTab) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;

        if (notifications.isEmpty) {
          return const Center(child: Text("No notifications found."));
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif =
            notifications[index].data() as Map<String, dynamic>;

            final title = notif["title"] ?? "";
            final message = notif["message"] ?? "";
            final requestId = notif["requestId"] ?? "";

            final timestamp = notif["timestamp"] as Timestamp?;
            final date = timestamp?.toDate() ?? DateTime.now();
            final formattedTime =
                "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

            final isRead = notif["isRead"] ?? false;

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
                      style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                onTap: () async {
                  FirebaseFirestore.instance
                      .collection("notifications")
                      .doc(notifications[index].id)
                      .update({"isRead": true});

                  if (requestId.isEmpty) return;

                  // Load request data
                  final reqSnap = await FirebaseFirestore.instance
                      .collection("requests")
                      .doc(requestId)
                      .get();

                  if (!reqSnap.exists) return;

                  final requestData =
                  reqSnap.data() as Map<String, dynamic>;

                  // ----------------------------------------------------
                  // RECEIVER TAB → Open ConfirmRequestScreen
                  // ----------------------------------------------------
                  if (isReceiverTab && title == "Request Submitted") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ConfirmRequestScreen(requestId: requestId),
                      ),
                    );
                    return;
                  }

                  // ----------------------------------------------------
                  // DONOR TAB → Only New Donation Request opens details
                  // ----------------------------------------------------
                  if (!isReceiverTab &&
                      title == "New Donation Request") {
                    final receiverUid =
                        requestData["receiverUid"] ?? notif["fromUid"] ?? "";

                    if (receiverUid.toString().isEmpty) return;

                    final receiverData =
                    await _getUserDetails(receiverUid.toString());

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationDetailScreen(
                          donorPhone: receiverData["phone"] ?? "",
                          receiverPhone: receiverData["phone"] ?? "",
                          receiverAddress: receiverData["address"] ?? "",
                          donationData: requestData,
                        ),
                      ),
                    );
                    return;
                  }

                  // Request Confirmed → do nothing
                  return;
                },
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Notifications",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF87CEEB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: "Receiver"),
            Tab(text: "Donor"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_receiverNotifications(), true),
          _buildNotificationList(_donorNotifications(), false),
        ],
      ),
    );
  }
}
