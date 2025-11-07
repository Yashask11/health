// lib/request_detail_screen.dart
import 'package:flutter/material.dart';
import 'models/request.dart';

class RequestDetailScreen extends StatelessWidget {
  final Request request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final String itemName = request.itemName;
    final int quantity = _safeInt(request.quantity) ?? 1;
    final String receiverName = request.receiverName;
    final String phone = request.receiverPhone;
    final String address = '-'; // Address not in model
    final int available = 0; // Available not in model
    final String status = request.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildDetailRow("👤 Receiver", receiverName),
                const SizedBox(height: 12),
                _buildDetailRow("📞 Contact", phone),
                const SizedBox(height: 12),
                _buildDetailRow("🏠 Address", address),
                const SizedBox(height: 12),
                _buildDetailRow(
                  "✅ Available",
                  available > 0 ? "Yes" : "No",
                  valueColor: available > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                _buildDetailRow("📌 Status", status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt();
    return null;
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
