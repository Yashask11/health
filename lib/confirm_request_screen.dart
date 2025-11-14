import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmRequestScreen extends StatefulWidget {
  final String requestId;

  const ConfirmRequestScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends State<ConfirmRequestScreen> {
  Map<String, dynamic>? requestData;

  String donorName = "-";
  String donorPhone = "-";
  String donorEmail = "-";
  String donorAddress = "-";

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      // ⭐ LOAD REQUEST
      final reqSnap = await FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .get();

      if (!reqSnap.exists) {
        setState(() => loading = false);
        return;
      }

      requestData = reqSnap.data()!;

      // ⭐ FETCH DONOR DETAILS FROM USERS COLLECTION
      final donorUid = requestData!['donorUid'];
      if (donorUid != null && donorUid.toString().isNotEmpty) {
        await _loadDonorDetails(donorUid);
      }

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadDonorDetails(String donorUid) async {
    final donorDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(donorUid)
        .get();

    if (!donorDoc.exists) return;

    final data = donorDoc.data()!;
    donorName = data['name'] ?? "-";
    donorPhone = data['phone'] ?? "-";
    donorEmail = data['email'] ?? "-";

    if (data['address'] != null && data['address'] is Map) {
      final a = Map<String, dynamic>.from(data['address']);
      donorAddress = [
        a['street'],
        a['city'],
        a['state'],
        a['pincode']
      ]
          .where((v) => v != null && v.toString().isNotEmpty)
          .join(", ");
    }
  }

  Future<void> _confirmRequest() async {
    await FirebaseFirestore.instance
        .collection("requests")
        .doc(widget.requestId)
        .update({"status": "Confirmed"});

    // Optionally notify donor later (not required now)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Request confirmed successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (requestData == null) {
      return const Scaffold(
        body: Center(child: Text("Request not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Request"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Confirm Your Request",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ⭐ ITEM NAME
                  _row("Item Name", requestData!["itemName"] ?? "-"),

                  // ⭐ ITEM TYPE
                  _row("Type", requestData!["type"] ?? "-"),

                  // ⭐ IMAGE
                  if (requestData!["imageUrl"] != null &&
                      requestData!["imageUrl"].toString().isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.network(
                          requestData!["imageUrl"],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  const Divider(height: 30, thickness: 1),

                  const Text(
                    "Donor Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _row("👤 Name", donorName),
                  _row("📞 Phone", donorPhone),
                  _row("✉ Email", donorEmail),
                  _row("🏠 Address", donorAddress),

                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: _confirmRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                      ),
                      child: const Text(
                        "Confirm Request",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
