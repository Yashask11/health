import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationDetailPage extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const DonationDetailPage({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    // ✅ Convert Firestore Timestamp to readable date
    String formatExpiryDate(dynamic value) {
      if (value == null) return "N/A";
      if (value is Timestamp) {
        final date = value.toDate();
        return "${date.day}/${date.month}/${date.year}";
      } else {
        return value.toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(itemData['itemName'] ?? "Donation Details"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemData['imageUrl'] != null && itemData['imageUrl'] != "")
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  itemData['imageUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_not_supported,
                    size: 80, color: Colors.grey),
              ),
            const SizedBox(height: 20),

            Text(
              itemData['itemName'] ?? "Unknown Item",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.category, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  itemData['type'] ?? "Unknown Type",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (itemData['available'] != null)
              Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    "Available: ${itemData['available']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            if (itemData['expiryDate'] != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    "Expiry Date: ${formatExpiryDate(itemData['expiryDate'])}",
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            const Divider(),

            const Text(
              "Donor Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (itemData['donorName'] != null)
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("Name: ${itemData['donorName']}"),
                ],
              ),
            const SizedBox(height: 8),

            if (itemData['donorEmail'] != null)
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("Email: ${itemData['donorEmail']}"),
                ],
              ),
            const SizedBox(height: 8),

            if (itemData['donorPhone'] != null)
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text("Phone: ${itemData['donorPhone']}"),
                ],
              ),
            const SizedBox(height: 20),

            if (itemData['description'] != null &&
                itemData['description'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    itemData['description'],
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
