import 'dart:io';
import 'package:flutter/material.dart';
import 'models/donation.dart'; // ✅ Import your donation model

class DonationDetailScreen extends StatelessWidget {
  final Donation donation;

  const DonationDetailScreen({
    super.key,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Light background
      appBar: AppBar(
        title: const Text("Donation Details"),
        backgroundColor: Colors.lightBlueAccent, // ✅ Sky blue app bar
        foregroundColor: Colors.white,
        elevation: 3,
      ),

      // ---------- BODY ----------
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ---------- Item Name ----------
            Center(
              child: Text(
                donation.itemName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- Quantity ----------
            _buildDetailRow(Icons.inventory, "Quantity", "${donation.quantity}"),
            const SizedBox(height: 12),

            // ---------- Expiry Date (only for Medicine) ----------
            if (donation.type == DonationType.medicine &&
                donation.expiryDate != null)
              _buildDetailRow(
                Icons.date_range,
                "Expiry Date",
                "${donation.expiryDate!.day}-${donation.expiryDate!.month}-${donation.expiryDate!.year}",
              ),

            // ---------- Condition (only for Equipment) ----------
            if (donation.type == DonationType.equipment &&
                donation.condition != null)
              _buildDetailRow(Icons.build, "Condition", donation.condition!),

            const SizedBox(height: 12),

            // ---------- Donor Information ----------
            _buildDetailRow(Icons.person, "Donor Name", donation.donorName),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone, "Phone", donation.phone),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, "Address", donation.address),
            const SizedBox(height: 12),

            // ---------- Availability ----------
            _buildDetailRow(
              Icons.check_circle,
              "Available",
              donation.available > 0 ? "Yes" : "No",
            ),

            const SizedBox(height: 20),

            // ---------- Image Section ----------
            if (donation.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  donation.imageFile!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "No Image Provided",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Helper Widget ----------
  /// Builds a clean, consistent detail row with an icon, label, and value.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.lightBlue),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
