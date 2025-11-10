import 'package:flutter/material.dart';

class DonationDetailPage extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const DonationDetailPage({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
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
            // ✅ Image Section
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

            // ✅ Item Name
            Text(
              itemData['itemName'] ?? "Unknown Item",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // ✅ Type
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

            // ✅ Availability
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

            // ✅ Expiry Date
            if (itemData['expiryDate'] != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    "Expiry Date: ${itemData['expiryDate']}",
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            const Divider(),

            // ✅ Donor Info Section
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

            // ✅ Notes or Description
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
