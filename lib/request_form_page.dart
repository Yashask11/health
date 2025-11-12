import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_detail_screen.dart';

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _userName = "";
  String _userPhone = "";
  String _userEmail = "";
  String _userUid = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userUid = user.uid;
    _userEmail = user.email ?? "";

    final doc =
    await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _userName = data['name'] ?? "";
        _userPhone = data['phone'] ?? "";
      });
    }
  }

  Future<void> _requestItem(DocumentSnapshot item) async {
    try {
      final data = item.data() as Map<String, dynamic>? ?? {};

      await FirebaseFirestore.instance.collection("requests").add({
        "receiverUid": _userUid,
        "receiverName": _userName,
        "receiverEmail": _userEmail,
        "receiverPhone": _userPhone,
        "donorUid": data['donorUid'],
        "itemName": data['itemName'],
        "type": data['type'],
        "timestamp": FieldValue.serverTimestamp(),
        "status": "Pending",
        "imageUrl": data['imageUrl'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Request sent. Waiting for donor approval."),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection("requests")
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Request cancelled successfully."),
          backgroundColor: Colors.redAccent,
        ),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error cancelling request: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildItemCard(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: (data['imageUrl'] != null && data['imageUrl'] != "")
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            data['imageUrl'],
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.image, size: 50, color: Colors.grey),
        title: Text(
          data['itemName'] ?? "Unnamed Item",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Flexible( // ✅ Prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['expiryDate'] != null)
                Text(
                  "Expiry: ${data['expiryDate']}",
                  style: const TextStyle(color: Colors.red),
                ),
              if (data['available'] != null)
                Text("Available: ${data['available']}"),
            ],
          ),
        ),
        trailing: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("requests")
              .where("receiverUid", isEqualTo: _userUid)
              .where("itemName", isEqualTo: data['itemName'])
              .where("status", isEqualTo: "Pending")
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            final alreadyRequested =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            if (alreadyRequested) {
              final requestId = snapshot.data!.docs.first.id;
              return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Pending",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _cancelRequest(requestId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
              );
            }

            return ElevatedButton(
              onPressed: () => _requestItem(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
              ),
              child: const Text("Request"),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonationDetailPage(itemData: data),
            ),
          );
        },
      ),
    );
  }

  Widget _medicinesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("type", isEqualTo: "Medicine")
          .where("donorUid", isNotEqualTo: _userUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("No medicines available"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, i) => _buildItemCard(docs[i]),
        );
      },
    );
  }

  Widget _equipmentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("type", isEqualTo: "Equipment")
          .where("donorUid", isNotEqualTo: _userUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("No equipment available"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, i) => _buildItemCard(docs[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Donations"),
        backgroundColor: Colors.lightBlue,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.medication), text: "Medicines"),
            Tab(icon: Icon(Icons.medical_services), text: "Equipment"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _medicinesTab(),
          _equipmentTab(),
        ],
      ),
    );
  }
}
