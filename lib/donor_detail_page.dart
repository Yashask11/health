import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationDetailPage extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const DonationDetailPage({super.key, required this.itemData});

  @override
  State<DonationDetailPage> createState() => _DonationDetailPageState();
}

class _DonationDetailPageState extends State<DonationDetailPage> {
  Map<String, dynamic>? donorData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDonorDetails();
  }

  Future<void> _loadDonorDetails() async {
    try {
      final donorUid = widget.itemData['donorUid'];
      if (donorUid != null && donorUid != '') {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(donorUid)
            .get();
        if (doc.exists) donorData = doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching donor: $e');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.itemData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Colors.lightBlue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageUrl'] != null && data['imageUrl'] != "")
              Center(
                child: Image.network(
                  data['imageUrl'],
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              data['itemName'] ?? '',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Type: ${data['type'] ?? '-'}'),
            if (data['available'] != null)
              Text('Available Quantity: ${data['available']}'),
            if (data['expiryDate'] != null)
              Text('Expiry Date: ${data['expiryDate']}'),
            const Divider(height: 32),
            const Text('Donor Details',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (donorData != null) ...[
              Text('Name: ${donorData!['name'] ?? '-'}'),
              Text('Email: ${donorData!['email'] ?? '-'}'),
              Text('Phone: ${donorData!['phone'] ?? '-'}'),
              if (donorData!['address'] != null)
                Text('Address: ${donorData!['address']}'),
            ] else
              const Text('Donor information not available.'),
          ],
        ),
      ),
    );
  }
}
