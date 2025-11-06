import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// removed receiver_form.dart (not used here)
import 'receiver_form.dart';
import 'donor_form.dart';
import 'admin.dart';
import 'models/request.dart';
import 'models/donation.dart';
import 'profile_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'request_detail_screen.dart';
import 'donation_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  final List<Request> requests = [];
  final List<Donation> donations = [];

  final CollectionReference donationsRef =
  FirebaseFirestore.instance.collection('donations');
  final CollectionReference requestsRef =
  FirebaseFirestore.instance.collection('requests');

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
    } else {
      // no signed-in user — set defaults
      userName = "Guest";
      userPhone = "N/A";
    }
  }

  Future<void> _loadUserDetails() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['name'] ?? 'User';
          userPhone = data['phone'] ?? 'N/A';
        });

        // Start listeners after we have user info
        _listenToUserDonations();
        _listenToUserRequests();
      } else {
        setState(() {
          userName = "User";
          userPhone = "N/A";
        });
        _listenToUserDonations();
        _listenToUserRequests();
      }
    } catch (e, st) {
      // log and continue with defaults
      debugPrint('Error loading user details: $e\n$st');
      setState(() {
        userName = "User";
        userPhone = "N/A";
      });
      _listenToUserDonations();
      _listenToUserRequests();
    }
  }

  void _listenToUserDonations() {
    final user = currentUser;
    if (user == null) return;

    donationsRef.where('donorEmail', isEqualTo: user.email).snapshots().listen(
          (snapshot) {
        try {
          final List<Donation> loaded = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // if Donation.fromMap accepts id pass it, otherwise remove id param
            try {
              return Donation.fromMap(data, id: doc.id);
            } catch (_) {
              return Donation.fromMap(data);
            }
          }).toList();

          setState(() {
            donations
              ..clear()
              ..addAll(loaded);
          });
        } catch (e, st) {
          debugPrint('Error parsing donations snapshot: $e\n$st');
        }
      },
      onError: (err) => debugPrint('Donations snapshot error: $err'),
    );
  }

  void _listenToUserRequests() {
    final user = currentUser;
    if (user == null) return;

    // If this query triggers "requires index" at runtime, create the composite index in Firebase.
    requestsRef
        .where('receiverUid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        try {
          final List<Request> loaded = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Request.fromMap(data, id: doc.id);
          }).toList();

          setState(() {
            requests
              ..clear()
              ..addAll(loaded);
          });
        } catch (e, st) {
          debugPrint('Error parsing requests snapshot: $e\n$st');
        }
      },
      onError: (err) => debugPrint('Requests snapshot error: $err'),
    );
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

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 60,
        width: 60,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            height: 60,
            width: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
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
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                            DonationDetailScreen(donation: item),
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
          },
        ),
      ],
    );
  }

  void _openDonationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("My Donations")),
          body: _buildSection<Donation>(
            title: "My Donations",
            items: donations,
            emptyText: "No donations yet",
            icon: Icons.volunteer_activism,
            iconColor: Colors.orange,
            itemText: (d) =>
            "${d.itemName} (x${d.quantity}) • ${d.donorName} • ${d.donorPhone}",
          ),
        ),
      ),
    );
  }

  void _openRequestsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("My Requests")),
          body: _buildSection<Request>(
            title: "My Requests",
            items: requests,
            emptyText: "No requests yet",
            icon: Icons.inventory,
            iconColor: Colors.green,
            itemText: (r) =>
            "${r.itemName} • ${r.status} • ${r.receiverName} (${r.receiverPhone})",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmailLocal = currentUser?.email ?? userEmail;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: Drawer(
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
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text("My Donations"),
              onTap: () {
                Navigator.pop(context);
                _openDonationsPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.request_page),
              title: const Text("My Requests"),
              onTap: () {
                Navigator.pop(context);
                _openRequestsPage();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Sign Out",
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // optionally refresh manually
          // no-op because listeners are live
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBigButton("Donor", "assets/donor.png", _openDonor),
              _buildBigButton("Receiver", "assets/receiver.png", _openReceiver),
              _buildBigButton("Admin", "assets/admin.png", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              }),
              const SizedBox(height: 20),
              _buildSection<Donation>(
                title: "My Donations",
                items: donations,
                emptyText: "No donations yet",
                icon: Icons.volunteer_activism,
                iconColor: Colors.orange,
                itemText: (d) =>
                "${d.itemName} (x${d.quantity}) • ${d.donorName} • ${d.donorPhone}",
              ),
              const SizedBox(height: 20),
              _buildSection<Request>(
                title: "My Requests",
                items: requests,
                emptyText: "No requests yet",
                icon: Icons.inventory,
                iconColor: Colors.green,
                itemText: (r) =>
                "${r.itemName} • ${r.status} • ${r.receiverName} (${r.receiverPhone})",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
