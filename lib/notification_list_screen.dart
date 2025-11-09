import 'package:flutter/material.dart';
import 'models/notification_model.dart';

class NotificationListScreen extends StatelessWidget {
  final List<AppNotification> notifications;

  const NotificationListScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (_, i) {
          final n = notifications[i];
          final dt = n.timestamp; // ✅ Convert Timestamp → DateTime
          final time =
              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.notifications,
                color: Colors.red,
              ),
              title: Text(n.title),
              subtitle: Text(n.message),
              trailing: Text(
                time,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}