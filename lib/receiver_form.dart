import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userUid = user.uid;
    _userEmail = user.email ?? "";

    final doc =
    await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists) {
      setState(() {
        _userName = doc['name'] ?? "";
        _userPhone = doc['phone'] ?? "";
      });
    }
  }

  Future<void> _requestItem(DocumentSnapshot item) async {
    try {
      final docId = item.id;
      final data = item.data() as Map<String, dynamic>;

      if (data['available'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Item not available"), backgroundColor: Colors.red),
        );
        return;
      }

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
        "donationId": docId, // ✅ link back to the donation
      });

      await FirebaseFirestore.instance
          .collection("donations")
          .doc(docId)
          .update({"available": data['available'] - 1});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Request sent successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  /// ✅ Cancel request function
  Future<void> _cancelRequest(DocumentSnapshot request) async {
    try {
      final data = request.data() as Map<String, dynamic>;
      final donationId = data['donationId'];

      // Restore availability
      if (donationId != null) {
        final donationRef =
        FirebaseFirestore.instance.collection("donations").doc(donationId);
        final donationDoc = await donationRef.get();
        if (donationDoc.exists) {
          final currentAvailable = donationDoc['available'] ?? 0;
          await donationRef.update({"available": currentAvailable + 1});
        }
      }

      // Delete request
      await FirebaseFirestore.instance
          .collection("requests")
          .doc(request.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Request canceled"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildItemCard(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: data['imageUrl'] != null && data['imageUrl'] != ""
            ? Image.network(data['imageUrl'],
            width: 70, height: 70, fit: BoxFit.cover)
            : const Icon(Icons.image, size: 50),
        title: Text(
          data['itemName'] ?? "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['expiryDate'] != null)
              Text("Expiry: ${data['expiryDate']}",
                  style: const TextStyle(color: Colors.red)),
            Text("Available: ${data['available']}"),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _requestItem(item),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
          child: const Text("Request"),
        ),
      ),
    );
  }

  Widget _medicinesTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("type", isEqualTo: "Medicine")
          .where("available", isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
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
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("donations")
          .where("type", isEqualTo: "Equipment")
          .where("available", isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
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

  /// ✅ NEW TAB: My Requests
  Widget _myRequestsTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("receiverUid", isEqualTo: _userUid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No requests yet"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isPending = data['status'] == "Pending";

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: data['imageUrl'] != null && data['imageUrl'] != ""
                    ? Image.network(data['imageUrl'],
                    width: 70, height: 70, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 50),
                title: Text(
                  data['itemName'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Type: ${data['type']}"),
                    Text("Status: ${data['status']}",
                        style: TextStyle(
                          color: data['status'] == "Pending"
                              ? Colors.orange
                              : data['status'] == "Approved"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                trailing: isPending
                    ? TextButton(
                  onPressed: () => _cancelRequest(docs[i]),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent),
                  child: const Text("Cancel"),
                )
                    : null,
              ),
            );
          },
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
            Tab(icon: Icon(Icons.history), text: "My Requests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _medicinesTab(),
          _equipmentTab(),
          _myRequestsTab(),
        ],
      ),
    );
  }
}
