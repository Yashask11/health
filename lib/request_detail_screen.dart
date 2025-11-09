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
          donorName = _asString(data['name']);
          donorPhone = _asString(data['phone']);
          donorEmail = _asString(data['email']);
          donorAddress = _asString(data['address']);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint('Error fetching donor details: $e');
      setState(() => loading = false);
    }
  }

  String _asString(dynamic v) {
    if (v == null) return '-';
    if (v is String) return v;
    if (v is Map) return v.values.join(', ');
    if (v is List) return v.join(', ');
    return v.toString();
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt();
    return null;
  }

  Future<void> _notifyDonor() async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': widget.request.donorUid,
        'fromUid': widget.request.receiverUid,
        'title': 'New Request Received',
        'body': '${widget.request.itemName} has been requested.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent to donor!')),
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
    final String itemName = request.itemName;
    final int quantity = _safeInt(request.quantity) ?? 1;
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
                          errorBuilder: (c, e, s) =>
                          const Icon(Icons.broken_image, size: 80),
                          loadingBuilder: (c, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 160,
                              width: 160,
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
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
                      itemName,
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
                  const SizedBox(height: 8),
                  _buildDetailRow("📞 Phone", donorPhone),
                  const SizedBox(height: 8),
                  _buildDetailRow("✉️ Email", donorEmail),
                  const SizedBox(height: 8),
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
