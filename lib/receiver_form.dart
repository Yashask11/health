import 'package:flutter/material.dart';
import 'models/request.dart';

class ReceiverForm extends StatefulWidget {
  const ReceiverForm({super.key});

  @override
  State<ReceiverForm> createState() => _ReceiverFormState();
}

class _ReceiverFormState extends State<ReceiverForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? selectedItem;
  int selectedQuantity = 1;

  // Dummy items for receiver to select
  final List<Map<String, dynamic>> availableItems = [
    {"name": "Wheelchair", "available": 10},
    {"name": "Walking stick", "available": 20},
    {"name": "Paracetamol tablet", "available": 15},
    {"name": "Oxygen Concentrator", "available": 25},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50, // 🌿 Light green background
      appBar: AppBar(
        title: const Text("Receiver Page"),
        backgroundColor: Colors.green.shade700, // Dark green AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                color: Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    value: selectedItem,
                    dropdownColor: Colors.green.shade100,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Item",
                    ),
                    items: availableItems.map((item) {
                      return DropdownMenuItem<String>(
                        value: item["name"] as String,
                        child: Text(
                          "${item["name"]} (Available: ${item["available"]})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedItem = val);
                    },
                    validator: (val) =>
                    val == null ? "Please select an item" : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🌿 Quantity Selector
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                color: Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        "Quantity:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () {
                          if (selectedQuantity > 1) {
                            setState(() => selectedQuantity--);
                          }
                        },
                      ),
                      Text(
                        "$selectedQuantity",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          setState(() => selectedQuantity++);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🌿 Receiver Details
              _buildInputField("Receiver Name", _nameController),
              _buildInputField("Phone", _phoneController,
                  keyboardType: TextInputType.phone),
              _buildInputField("Address", _addressController),

              const SizedBox(height: 20),

              // 🌿 Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedItem != null) {
                    final selected = availableItems
                        .firstWhere((i) => i["name"] == selectedItem);

                    final request = Request(
                      itemName: selectedItem!,
                      quantity: selectedQuantity,
                      available: selected["available"] as int,
                      receiverName: _nameController.text,
                      phone: _phoneController.text,
                      address: _addressController.text,
                    );

                    Navigator.pop(context, request); // ✅ send back to HomeScreen
                  }
                },
                child: const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌿 Custom green input fields
  Widget _buildInputField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.green.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (val) => val!.isEmpty ? "Enter $label" : null,
      ),
    );
  }
}
