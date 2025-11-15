import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_detail_screen.dart';
import 'models/request.dart';
import 'request_detail_screen.dart';

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

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        _userName = data['name'] ?? "";
        _userPhone = data['phone'] ?? "";
      });
    }
  }

  Future<void> _requestItem(Map<String, dynamic> donorData) async {
    try {
      final correctDonorUid =
          donorData['uid'] ?? donorData['donorUid'] ?? "";

      if (correctDonorUid.isEmpty) {
        throw "Donor UID missing!";
      }

      final reqRef = await FirebaseFirestore.instance
          .collection("requests")
          .add({
        "receiverUid": _userUid,
        "receiverName": _userName,
        "receiverEmail": _userEmail,
        "receiverPhone": _userPhone,

        "donorUid": correctDonorUid,
        "itemName": donorData['itemName'],
        "expiryDate": donorData['expiryDate'],
        "type": donorData['type'],

        "imageUrl": donorData['imageUrl'],
        "quantity": donorData['quantity'] ?? 1,

        // *** IMPORTANT NEW FIELD ***
        "donationId": donorData['donationId'],

        "timestamp": FieldValue.serverTimestamp(),
        "status": "Pending",
      });

      final reqDoc = await FirebaseFirestore.instance
          .collection("requests")
          .doc(reqRef.id)
          .get();

      final request = Request.fromMap(
        reqDoc.id,
        reqDoc.data() as Map<String, dynamic>,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestDetailScreen(request: request),
        ),
      );

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': _userUid,
        'fromUid': _userUid,
        'requestId': reqRef.id,
        'title': 'Request Submitted',
        'message': 'Your request has been submitted. Tap to confirm.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

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

  Widget _buildGroupedItemCard(
      String groupKey, List<Map<String, dynamic>> donors, String type) {
    final firstItem = donors.first;
    final nameParts = groupKey.split("||");
    final itemName = nameParts[0];
    final expiryDate = nameParts.length > 1 ? nameParts[1] : "";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        leading: (firstItem['imageUrl'] != null &&
            firstItem['imageUrl'] != "")
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            firstItem['imageUrl'],
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.image, size: 50, color: Colors.grey),
        title: Text(
          itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          expiryDate.isNotEmpty
              ? "Expiry: $expiryDate • ${donors.length} donor(s)"
              : "${donors.length} donor(s)",
          style: const TextStyle(color: Colors.grey),
        ),
        children: donors.map((donor) {
          return ListTile(
            title: Text("Donor: ${donor['donorName'] ?? 'Unknown'}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (donor['available'] != null)
                  Text("Available: ${donor['available']}"),
              ],
            ),
            trailing: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection("requests")
                  .where("receiverUid", isEqualTo: _userUid)
                  .where("itemName", isEqualTo: donor['itemName'])
                  .where("expiryDate", isEqualTo: donor['expiryDate'])
                  .where("donorUid", isEqualTo: donor['uid'])
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

                  return FittedBox(
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  );
                }

                return ElevatedButton(
                  onPressed: () => _requestItem(donor),
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
                  builder: (context) =>
                      DonationDetailPage(itemData: donor),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupedList(QuerySnapshot snapshot, String type) {
    final docs = snapshot.docs;
    if (docs.isEmpty) {
      return Center(child: Text("No $type available"));
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // *** IMPORTANT: Attach donationId to the map ***
      data['donationId'] = doc.id;

      final name = data['itemName'] ?? "Unnamed Item";
      final expiry = data['expiryDate'] ?? "No Expiry";
      final key = "$name||$expiry";

      grouped.putIfAbsent(key, () => []).add(data);
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: grouped.entries
          .map((entry) =>
          _buildGroupedItemCard(entry.key, entry.value, type))
          .toList(),
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
        return _buildGroupedList(snapshot.data!, "medicines");
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
        return _buildGroupedList(snapshot.data!, "equipment");
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
