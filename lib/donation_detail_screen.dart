import 'package:flutter/material.dart';
import 'models/donation.dart'; // ✅ Import your Donation model

class DonationDetailScreen extends StatelessWidget {
  final Donation donation;

  const DonationDetailScreen({
    super.key,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Donation Details"),
        backgroundColor: Colors.lightBlueAccent,
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
            _buildDetailRow(Icons.phone, "Phone", donation.donorPhone), // ✅ updated field
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
            if (donation.imageUrl != null && donation.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  donation.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildNoImageContainer("Image failed to load");
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              _buildNoImageContainer("No Image Provided"),
          ],
        ),
      ),
    );
  }

  // ---------- Helper Widget ----------
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

  Widget _buildNoImageContainer(String message) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
