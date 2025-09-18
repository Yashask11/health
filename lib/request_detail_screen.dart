import 'package:flutter/material.dart';
import 'models/request.dart';

class RequestDetailScreen extends StatelessWidget {
  final Request request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.itemName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("Quantity: ${request.quantity}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Requested by: ${request.receiverName}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Contact: ${request.receiverContact ?? "Not provided"}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Address: ${request.receiverAddress ?? "Not provided"}",
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
