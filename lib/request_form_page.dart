import 'package:flutter/material.dart';

class RequestFormPage extends StatefulWidget {
  final String itemName;        // item user tapped
  final String availableText;   // e.g., "10kg", "20 pieces"

  const RequestFormPage({
    super.key,
    required this.itemName,
    required this.availableText,
  });

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final orgNameCtrl = TextEditingController();

  String receiverType = "Individual"; // default selection

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    orgNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request ${widget.itemName}"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Container(
        color: Colors.green.shade100,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ✅ Show availability info
              Text(
                "Available: ${widget.availableText}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Receiver Type Selection
              const Text(
                "Receiver Type:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Individual"),
                      value: "Individual",
                      groupValue: receiverType,
                      onChanged: (val) {
                        setState(() => receiverType = val!);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Organization"),
                      value: "Organization",
                      groupValue: receiverType,
                      onChanged: (val) {
                        setState(() => receiverType = val!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ✅ Organization field only for "Organization" type
              if (receiverType == "Organization")
                TextFormField(
                  controller: orgNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Organization Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (receiverType == "Organization" &&
                        (v == null || v.isEmpty)) {
                      return "Please enter organization name";
                    }
                    return null;
                  },
                ),
              if (receiverType == "Organization")
                const SizedBox(height: 10),

              // ✅ Receiver name
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Receiver Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter your name" : null,
              ),
              const SizedBox(height: 10),

              // ✅ Requested quantity
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Requested Quantity",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter quantity" : null,
              ),
              const SizedBox(height: 10),

              // ✅ Phone number
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (receiverType == "Individual" &&
                      (v == null || v.isEmpty)) {
                    return "Please enter phone number";
                  }
                  return null; // For organizations, can be optional
                },
              ),
              const SizedBox(height: 10),

              // ✅ Address
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter address" : null,
              ),
              const SizedBox(height: 20),

              // ✅ Submit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // You can modify this to return a Request object later
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Request placed for ${widget.itemName} "
                              "(${receiverType == 'Organization' ? orgNameCtrl.text : nameCtrl.text})",
                        ),
                      ),
                    );

                    Navigator.pop(context, true); // return to previous page
                  }
                },
                child: const Text(
                  "Place Request",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
