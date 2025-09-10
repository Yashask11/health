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

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
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
              Text(
                "Available: ${widget.availableText}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Receiver Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? "Please enter your name"
                    : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: "Requested Quantity",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter quantity" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter phone number" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Please enter address" : null,
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Simulate placing request
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Request placed for ${widget.itemName}",
                        ),
                      ),
                    );
                    Navigator.pop(context, true); // return to previous page
                  }
                },
                child: const Text("Place Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
