import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmRequestScreen extends StatefulWidget {
  final String requestId;

  const ConfirmRequestScreen({super.key, required this.requestId});

  @override
  State<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends State<ConfirmRequestScreen> {
  bool loading = true;

  // Request fields
  String itemName = "-";
  String type = "-";
  String donorUid = "";
  String expiryDate = "";
  String receiverUid = "";

  // Donor details
  String donorName = "-";
  String donorPhone = "-";
  String donorEmail = "-";
  String donorAddress = "-";

  @override
  void initState() {
    super.initState();
    _loadRequestAndDonor();
  }

  Future<void> _loadRequestAndDonor() async {
    try {
      final reqSnap = await FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .get();

      if (!reqSnap.exists) {
        setState(() => loading = false);
        return;
      }

      final data = reqSnap.data()!;
      itemName = data["itemName"] ?? "-";
      type = data["type"] ?? "-";
      donorUid = data["donorUid"] ?? "";
      expiryDate = data["expiryDate"] ?? "";
      receiverUid = data["receiverUid"] ?? "";

      // Load donor details
      await _loadDonorDetails();

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadDonorDetails() async {
    if (donorUid.isEmpty) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(donorUid).get();

      if (doc.exists) {
        final data = doc.data()!;
        donorName = data['name'] ?? '-';
        donorPhone = data['phone'] ?? '-';
        donorEmail = data['email'] ?? '-';

        donorAddress = data['address'] is Map
            ? [
          data['address']?['street'],
          data['address']?['city'],
          data['address']?['state'],
          data['address']?['pincode']
        ]
            .where((v) => v != null && v.toString().trim().isNotEmpty)
            .join(", ")
            : data['address']?.toString() ?? '-';
      }
    } catch (_) {}
  }

  // 🔥 STEP 1 + 2 + 3: Confirm → delete donation → notify donor
  Future<void> _confirmRequest() async {
    try {
      // STEP 1: UPDATE REQUEST STATUS
      await FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .update({"status": "Confirmed"});

      // STEP 2: DELETE THE DONATION DOCUMENT
      final donationSnap = await FirebaseFirestore.instance
          .collection("donations")
          .where("itemName", isEqualTo: itemName)
          .where("donorUid", isEqualTo: donorUid)
          .where("expiryDate", isEqualTo: expiryDate)
          .get();

      for (var doc in donationSnap.docs) {
        await FirebaseFirestore.instance
            .collection("donations")
            .doc(doc.id)
            .delete();
      }

      // STEP 3: NOTIFY DONOR
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': donorUid,
        'fromUid': receiverUid,
        'requestId': widget.requestId,
        'title': 'Request Confirmed',
        'message':
        'Your donation item "$itemName" has been confirmed by the receiver.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'donor_confirm',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request Confirmed! Donor Notified."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Request"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Confirm Your Request",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow("Item Name", itemName),
                  _buildDetailRow("Type", type),

                  const Divider(height: 30),
                  const Text("Donor Details",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),

                  _buildDetailRow("👤 Name", donorName),
                  _buildDetailRow("📞 Phone", donorPhone),
                  _buildDetailRow("✉ Email", donorEmail),
                  _buildDetailRow("🏠 Address", donorAddress),

                  const SizedBox(height: 25),

                  Center(
                    child: ElevatedButton(
                      onPressed: _confirmRequest,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12)),
                      child: const Text(
                        "Confirm Request",
                        style:
                        TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          Expanded(
            flex: 4,
            child: Text(value,
                style:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
