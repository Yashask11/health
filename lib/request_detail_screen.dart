import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/request.dart';

class RequestDetailScreen extends StatefulWidget {
  final Request request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  String donorName = '-';
  String donorPhone = '-';
  String donorEmail = '-';
  String donorAddress = '-';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDonorDetails();
  }

  Future<void> _loadDonorDetails() async {
    try {
      final donorUid = widget.request.donorUid;
      if (donorUid.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(donorUid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
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
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(", ")
              : data['address']?.toString() ?? '-';

          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ⭐ UPDATED: SEND NOTIFICATION TO DONOR + RECEIVER ⭐
  Future<void> _notifyDonor() async {
    try {
      // Fetch receiver (the requester)
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.request.receiverUid)
          .get();

      final receiverData = receiverDoc.data() ?? {};
      final String receiverPhone = receiverData['phone'] ?? '';

      String receiverAddress = "";
      if (receiverData['address'] != null && receiverData['address'] is Map) {
        final a = Map<String, dynamic>.from(receiverData['address']);
        receiverAddress = [
          a['street'],
          a['city'],
          a['state'],
          a['pincode']
        ]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .join(", ");
      }

      // ⭐ 1 — SEND NOTIFICATION TO DONOR
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.request.donorUid,      // donor gets this
        'fromUid': widget.request.receiverUid, // sender = receiver
        'requestId': widget.request.id,

        'title': 'New Donation Request',
        'message':
        '${receiverData['name'] ?? 'Someone'} has requested ${widget.request.itemName}.',

        'receiverPhone': receiverPhone,
        'receiverAddress': receiverAddress,

        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // ⭐ 2 — SEND NOTIFICATION TO RECEIVER ALSO
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.request.receiverUid,      // receiver gets this
        'fromUid': widget.request.receiverUid,    // for receiver tab filter
        'requestId': widget.request.id,

        'title': 'Request Submitted',
        'message': 'Your request has been sent. Tap to confirm.',

        // Send item details also
        'itemName': widget.request.itemName,
        'quantity': widget.request.quantity ?? 1,
        'type': widget.request.type,

        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    final int quantity = request.quantity ?? 1;
    final String status = request.status;
    final String imageUrl = request.imageUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
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
                  if (imageUrl.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 160,
                          width: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 80),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medical_services,
                            size: 80, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      request.itemName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  _buildDetailRow("📦 Quantity", "$quantity"),
                  const SizedBox(height: 12),
                  const Text("Donor details",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildDetailRow("👤 Name", donorName),
                  _buildDetailRow("📞 Phone", donorPhone),
                  _buildDetailRow("✉ Email", donorEmail),
                  _buildDetailRow("🏠 Address", donorAddress),
                  const SizedBox(height: 12),
                  _buildDetailRow("📌 Status", status),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _notifyDonor,
                      icon: const Icon(Icons.notifications_active,
                          color: Colors.white),
                      label: const Text(
                        "Notify Donor",
                        style: TextStyle(
                            fontSize: 16, color: Colors.white),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
        Expanded(
          flex: 4,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87)),
        ),
      ],
    );
  }
}