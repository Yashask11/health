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

  String? _userRole;
  String? _currentUid;
  int _unreadCount = 0; // ✅ Track unread notifications

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchUserRole();
    _listenForUnreadCount(); // ✅ Start listening for unread count
  }

  Future<void> _initNotifications() async {
    await _messaging.requestPermission();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification tapped: ${message.notification?.title}');
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'health_channel',
      'Health Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message!',
      notificationDetails,
    );

    debugPrint('✅ Local notification displayed!');
  }

  Future<void> _fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint("⚠ No user logged in.");
      return;
    }

    _currentUid = currentUser.uid;
    debugPrint("👤 Logged in UID: $_currentUid");

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();

      if (doc.exists) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'receiver';
        });
        debugPrint("✅ User role fetched: $_userRole");
      } else {
        debugPrint("⚠ No user document found for UID $_currentUid");
      }
    } catch (e) {
      debugPrint("❌ Error fetching user role: $e");
    }
  }

  // ✅ Stream for fetching notifications
  Stream<QuerySnapshot> _getNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint("⚠ User not logged in — empty stream returned.");
      return const Stream.empty();
    }

    final uid = currentUser.uid;
    debugPrint("📡 Fetching notifications for UID: $uid");

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ Listen for unread notifications count in real time
  void _listenForUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false) // field should exist in your Firestore
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadCount = snapshot.docs.length;
      });
    });
  }

  // ✅ Mark all as read when opening screen
  Future<void> _markAllAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final batch = FirebaseFirestore.instance.batch();

    final unreadDocs = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("❌ Firestore error: ${snapshot.error}");
            return Center(
              child: Text('Error loading notifications: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint("📭 No notifications found for this user.");
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          debugPrint("📬 Notifications count: ${notifications.length}");

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif =
              notifications[index].data() as Map<String, dynamic>;

              final title = notif['title'] ?? 'New Notification';
              final message = notif['message'] ?? notif['body'] ?? '';
              final fromName = notif['fromName'] ?? 'Someone';
              final time = notif['timestamp'] != null
                  ? (notif['timestamp'] as Timestamp).toDate()
                  : DateTime.now();
              final isRead = notif['isRead'] ?? false;

              final formattedTime =
                  '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isRead ? Colors.white : Colors.blue.shade50, // Unread highlight
                child: ListTile(
                  leading: const Icon(Icons.notifications_active,
                      color: Colors.blue),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$message\nFrom: $fromName'),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Mark as read when tapped
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notifications[index].id)
                        .update({'isRead': true});
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
