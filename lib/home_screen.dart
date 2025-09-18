import 'package:flutter/material.dart';
import 'receiver_form.dart';
import 'donor_form.dart';
import 'admin.dart';
import 'models/request.dart';
import 'models/donation.dart';
import 'profile_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'request_detail_screen.dart';
import 'donation_detail_screen.dart'; // 🔹 Import Donation detail screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Request> requests = [];
  final List<Donation> donations = [];

  Future<void> _openReceiver() async {
    final result = await Navigator.push<Request>(
      context,
      MaterialPageRoute(builder: (_) => const ReceiverForm()),
    );
    if (result != null) {
      setState(() => requests.add(result));
    }
  }

  Future<void> _openDonor() async {
    final result = await Navigator.push<Donation>(
      context,
      MaterialPageRoute(builder: (_) => const DonorForm()),
    );
    if (result != null) {
      setState(() => donations.add(result));
    }
  }

  // 🔹 Reusable Big Button
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

  // 🔹 Section Widget
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
                leading: Icon(icon, color: iconColor),
                title: Text(itemText(item)),

                // ✅ Navigate based on type
                onTap: () {
                  if (item is Request) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RequestDetailScreen(request: item),
                      ),
                    );
                  } else if (item is Donation) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DonationDetailScreen(donation: item),
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

  // 🔹 New Pages for full list
  void _openRequestsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("My Requests")),
          body: _buildSection<Request>(
            title: "Requests",
            items: requests,
            emptyText: "No requests yet",
            icon: Icons.inventory,
            iconColor: Colors.green,
            itemText: (r) =>
            "${r.itemName} (x${r.quantity}) • ${r.receiverName}",
          ),
        ),
      ),
    );
  }

  void _openDonationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("My Donations")),
          body: _buildSection<Donation>(
            title: "Donations",
            items: donations,
            emptyText: "No donations yet",
            icon: Icons.volunteer_activism,
            iconColor: Colors.orange,
            itemText: (d) =>
            "${d.itemName} (x${d.quantity}) • ${d.donorName}",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.blueAccent,
      ),

      // ✅ Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Yashas K"),
              accountEmail: Text("yashxas08@gmail.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
              ),
              decoration: BoxDecoration(color: Colors.blueAccent),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(
                      name: "Yashas K",
                      email: "yashxas08@gmail.com",
                      phone: "+91 9876543210",
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
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            _buildSection<Request>(
              title: "My Requests",
              items: requests,
              emptyText: "No requests yet",
              icon: Icons.inventory,
              iconColor: Colors.green,
              itemText: (r) =>
              "${r.itemName} (x${r.quantity}) • ${r.receiverName}",
            ),
            const SizedBox(height: 20),
            _buildSection<Donation>(
              title: "My Donations",
              items: donations,
              emptyText: "No donations yet",
              icon: Icons.volunteer_activism,
              iconColor: Colors.orange,
              itemText: (d) =>
              "${d.itemName} (x${d.quantity}) • ${d.donorName}",
            ),
          ],
        ),
      ),
    );
  }
}
