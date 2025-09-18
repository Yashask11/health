import 'package:flutter/material.dart';
import 'dart:io';
import 'models/donation.dart'; // ✅ correct import

class DonationDetailScreen extends StatelessWidget {
  final Donation donation;

  const DonationDetailScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donation Details"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              donation.itemName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Quantity: ${donation.quantity}"),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Expiry Date: ${donation.expiryDate}"),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.person, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Donor: ${donation.donorName}"),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.phone, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Phone: ${donation.phone}"),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(child: Text("Address: ${donation.address}")),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.teal),
                const SizedBox(width: 8),
                Text("Available: ${donation.available}"),
              ],
            ),
            const SizedBox(height: 20),

            if (donation.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  donation.imageFile as File,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text("No Image Provided"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
