import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmRequestScreen extends StatelessWidget {
  final String requestId;

  const ConfirmRequestScreen({super.key, required this.requestId});

  Future<void> _confirmRequest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'status': 'Confirmed'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request confirmed successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Request"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _confirmRequest(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          child: const Text(
            "Confirm Request",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
