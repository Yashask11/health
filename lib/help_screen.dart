import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support"), backgroundColor: Colors.blueAccent),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "For support, contact us at:\n\n📧 support@email.com\n📞 +91 9876543210",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
