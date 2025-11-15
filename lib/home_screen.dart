// (SAME IMPORTS – unchanged)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'request_form_page.dart';
import 'donor_form.dart';
import 'models/request.dart';
import 'models/donation.dart';
import 'profile_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'request_detail_screen.dart';
import 'donation_detail_screen.dart';
import 'notifications_screen.dart';
import 'models/notification_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  final List<Request> requests = [];
  final List<Donation> donations = [];
  final List<AppNotification> notifications = [];

  final CollectionReference donationsRef =
  FirebaseFirestore.instance.collection('donations');
  final CollectionReference requestsRef =
  FirebaseFirestore.instance.collection('requests');
  final CollectionReference notificationsRef =
  FirebaseFirestore.instance.collection('notifications');

  String userName = "Loading...";
  String userEmail = "";
  String userPhone = "";

  @override
  void initState() {
    super.initState();
    final user = currentUser;
    if (user != null) {
      userEmail = user.email ?? '';
      _loadUserDetails();
      _saveFcmToken();
    } else {
      userName = "Guest";
      userPhone = "N/A";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  Future<void> _saveFcmToken() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': fcmToken});
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          userName = (data['name'] ?? 'User').toString();
          userPhone = (data['phone'] ?? 'N/A').toString();
        });
      }

      _listenToUserDonations();
      _listenToUserRequests();
      _listenToNotifications();
    } catch (e) {
      debugPrint('Error loading user details: $e');
      _listenToUserDonations();
      _listenToUserRequests();
      _listenToNotifications();
    }
  }

  void _listenToNotifications() {
    final user = currentUser;
    if (user == null) return;

    notificationsRef
        .where(
      Filter.or(
        Filter('donorUid', isEqualTo: user.uid),
        Filter('receiverUid', isEqualTo: user.uid),
      ),
    )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AppNotification.fromMap(doc.id, data);
      }).toList();

      setState(() {
        notifications
          ..clear()
          ..addAll(loaded);
      });
    });
  }

  void _listenToUserDonations() {
    final user = currentUser;
    if (user == null) return;

    donationsRef
        .where('donorUid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Donation.fromMap(doc.id, data);
      }).toList();

      setState(() {
        donations
          ..clear()
          ..addAll(loaded);
      });
    });
  }

  void _listenToUserRequests() {
    final user = currentUser;
    if (user == null) return;

    requestsRef
        .where('receiverUid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Request.fromMap(doc.id, data);
      }).toList();

      setState(() {
        requests
          ..clear()
          ..addAll(loaded);
      });
    });
  }

  Future<void> _openReceiver() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceiverPage()),
    );
  }

  Future<void> _openDonor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DonorForm()),
    );
  }

  void _openNotificationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  // ✅ ONLY THIS METHOD IS NEW — no other changes
  Future<void> _deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // Confirmation popup
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete Firestore user doc
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete auth user
      await user.delete();

      // Sign out
      await FirebaseAuth.instance.signOut();

      // Redirect to login
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmailLocal = currentUser?.email ?? userEmail;

    final unreadCount =
        notifications.where((n) => n.isRead == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 30, color: Colors.white),
                onPressed: _openNotificationsPage,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),

      drawer: _buildDrawer(userEmailLocal),

      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBigButton("Donate", "assets/donor.png", _openDonor),
              _buildBigButton("Request", "assets/receiver.png", _openReceiver),
              const SizedBox(height: 24),
              _buildCardSection<Donation>(
                title: "My Donations",
                items: donations,
                emptyText: "No donations yet",
                icon: Icons.volunteer_activism,
                iconColor: Colors.orange,
                itemText: (d) => "${d.itemName} (x${d.quantity}) • ${d.donorName}",
              ),
              const SizedBox(height: 20),
              _buildCardSection<Request>(
                title: "My Requests",
                items: requests,
                emptyText: "No requests yet",
                icon: Icons.inventory,
                iconColor: Colors.green,
                itemText: (r) =>
                "${r.itemName} • ${r.status} • ${r.receiverName}",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(String userEmailLocal) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmailLocal),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
            ),
            decoration: const BoxDecoration(color: Colors.blueAccent),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    name: userName,
                    email: userEmailLocal,
                    phone: userPhone,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help & Support"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account",
                style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
            const Text("Sign Out", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported,
          size: 60, color: Colors.grey);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 60,
        width: 60,
      ),
    );
  }

  Widget _buildBigButton(String title, String assetPath, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 90,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Image.asset(assetPath, height: 45, width: 45),
          label: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildSection<T>({
    required String title,
    required List<T> items,
    required String emptyText,
    required IconData icon,
    required Color iconColor,
    required String Function(T) itemText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        items.isEmpty
            ? Center(child: Text(emptyText))
            : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  dense: true,
                  leading: item is Donation
                      ? _buildImage(item.imageUrl)
                      : Icon(icon, color: iconColor),
                  title: Text(itemText(item)),
                  onTap: () {
                    if (item is Donation) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DonationDetailPage(itemData: item.toMap()),
                        ),
                      );
                    } else if (item is Request) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestDetailScreen(request: item),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
      ],
    );
  }

  Widget _buildCardSection<T>({
    required String title,
    required List<T> items,
    required String emptyText,
    required IconData icon,
    required Color iconColor,
    required String Function(T) itemText,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _buildSection<T>(
          title: title,
          items: items,
          emptyText: emptyText,
          icon: icon,
          iconColor: iconColor,
          itemText: itemText,
        ),
      ),
    );
  }
}
