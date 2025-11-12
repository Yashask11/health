/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
        // ✅ FIXED: Changed donorUid → toUid
            .where('toUid', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.notifications),
                // ✅ Uses correct Firestore fields: title + body
                title: Text(data['title'] ?? 'New notification'),
                subtitle: Text(data['body'] ?? ''),
                trailing: Text(
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                      .split('.')[0]
                      : '',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    // 👇 Add this line to see which UID is logged in
    print("Current user UID: ${currentUser.uid}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUid', isEqualTo: currentUser.uid) // ✅ Check this field name
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          // 👇 Add this line to see how many notifications are fetched
          print("Notification docs count: ${snapshot.data!.docs.length}");

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(data['title'] ?? 'New notification'),
                subtitle: Text(data['body'] ?? 'No message'),
                trailing: Text(
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp)
                      .toDate()
                      .toString()
                      : '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Color(0xFF87CEEB), // sky blue appbar
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUid', isEqualTo: currentUser.uid) // ✅ Correct field name
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          debugPrint("📡 Notifications stream active for UID: ${currentUser.uid}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("❌ Firestore error: ${snapshot.error}");
            return const Center(child: Text("Error loading notifications"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint("⚠️ No notifications found for this user");
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!.docs;
          debugPrint("✅ Loaded ${notifications.length} notifications");

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? data['body'] ?? 'No message';
              final timestamp = data['timestamp'] is Timestamp
                  ? (data['timestamp'] as Timestamp).toDate()
                  : null;

              final formattedTime = timestamp != null
                  ? "${timestamp.day}/${timestamp.month}/${timestamp.year} "
                  "${timestamp.hour.toString().padLeft(2, '0')}:"
                  "${timestamp.minute.toString().padLeft(2, '0')}"
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.redAccent),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      if (formattedTime.isNotEmpty)
                        Text(
                          formattedTime,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    // ✅ Debug: print current UID
    debugPrint("👤 Logged-in user UID: ${currentUser.uid}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF87CEEB), // sky blue appbar
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUid', isEqualTo: currentUser.uid) // ✅ match your Firestore field
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ✅ Debug logs
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("⏳ Waiting for Firestore data...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("❌ Firestore error: ${snapshot.error}");
            return const Center(child: Text("Error loading notifications"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint("⚠️ No notifications found for UID: ${currentUser.uid}");
            return const Center(
              child: Text(
                "No notifications for this account.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          debugPrint("✅ Loaded ${notifications.length} notifications");

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? data['body'] ?? 'No message';
              final timestamp = data['timestamp'] is Timestamp
                  ? (data['timestamp'] as Timestamp).toDate()
                  : null;

              final formattedTime = timestamp != null
                  ? "${timestamp.day}/${timestamp.month}/${timestamp.year} "
                  "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}"
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading:
                  const Icon(Icons.notifications, color: Colors.redAccent),
                  title: Text(title,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      if (formattedTime.isNotEmpty)
                        Text(
                          formattedTime,
                          style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
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
*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 For Firestore
import 'package:firebase_auth/firebase_auth.dart'; // 🔹 To get current user
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

  Future<void> _initNotifications() async {
    // 🔸 Request notification permission
    await _messaging.requestPermission();

    // 🔸 Android initialization
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    // 🔸 Initialize local notifications
    await _localNotifications.initialize(initSettings);

    // 🔸 Listen to FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // 🔸 Handle when notification is tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification tapped: ${message.notification?.title}');
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
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

  // 🔹 Listen to Firestore notifications collection
  Stream<QuerySnapshot> _getNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    // 🔹 Fetch notifications only for logged-in donor
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('donorUid', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications yet'),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final title = notif['title'] ?? 'New Notification';
              final message = notif['message'] ?? '';
              final time = notif['timestamp'] != null
                  ? (notif['timestamp'] as Timestamp).toDate()
                  : DateTime.now();

              return ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.blue),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(message),
                trailing: Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

