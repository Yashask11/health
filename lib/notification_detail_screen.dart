import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String donorPhone;
  final String receiverPhone;
  final String receiverAddress;

  final Map<String, dynamic> donationData;

  // ⭐ NEW: to split UI for donor vs receiver
  final bool isReceiverNotification;

  const NotificationDetailScreen({
    super.key,
    required this.donorPhone,
    required this.receiverPhone,
    required this.receiverAddress,
    this.donationData = const {},
    this.isReceiverNotification = false,   // ⭐ default = Donor mode
  });

  Future<void> _makeCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Medicine details
    final String itemName = donationData["itemName"]?.toString() ?? "";
    final String quantity = donationData["quantity"]?.toString() ?? "";
    final String type = donationData["type"]?.toString() ?? "";
    final String condition = donationData["condition"]?.toString() ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donation Details"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volunteer_activism,
                      color: Colors.teal, size: 70),

                  const SizedBox(height: 20),

                  // ⭐ RECEIVER MODE MESSAGE
                  if (isReceiverNotification) ...[
                    const Text(
                      "Your request has been submitted successfully!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tap confirm to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      child: const Text("Confirm Request"),
                    ),

                    const SizedBox(height: 25),
                  ],

                  // ⭐ DONOR MODE (ORIGINAL UI)
                  if (!isReceiverNotification) ...[
                    const Text(
                      "For further queries about this donation, please contact the donor at:",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),

                    const SizedBox(height: 20),

                    InkWell(
                      onTap: donorPhone.isNotEmpty
                          ? () => _makeCall(donorPhone)
                          : null,
                      child: Text(
                        donorPhone.isNotEmpty
                            ? donorPhone
                            : "Phone not available",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (donorPhone.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: "Call",
                            onPressed: () => _makeCall(donorPhone),
                            icon: const Icon(Icons.call, color: Colors.teal),
                          ),
                          IconButton(
                            tooltip: "SMS",
                            onPressed: () => _sendSMS(donorPhone),
                            icon: const Icon(Icons.sms, color: Colors.blue),
                          ),
                        ],
                      ),

                    const SizedBox(height: 30),

                    if (receiverPhone.isNotEmpty)
                      Text(
                        "Receiver Phone: $receiverPhone",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),

                    if (receiverAddress.isNotEmpty)
                      Text(
                        "Receiver Address: $receiverAddress",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],

                  // ⭐ Medicine Details (same UI)
                  if (itemName.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text("Medicine: $itemName",
                        style: const TextStyle(fontSize: 16)),
                  ],
                  if (quantity.isNotEmpty)
                    Text("Quantity: $quantity",
                        style: const TextStyle(fontSize: 16)),
                  if (type.isNotEmpty)
                    Text("Type: $type",
                        style: const TextStyle(fontSize: 16)),
                  if (condition.isNotEmpty)
                    Text("Condition: $condition",
                        style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Back"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
