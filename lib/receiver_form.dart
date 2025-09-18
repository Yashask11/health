import 'package:flutter/material.dart';
import 'models/request.dart';

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Search
  final _searchController = TextEditingController();
  String searchQuery = "";

  // State
  String? selectedItem;
  int selectedQuantity = 1;
  bool showForm = false;

  // Dummy items
  final List<Map<String, dynamic>> availableItems = [
    {"name": "Wheelchair", "available": 10},
    {"name": "Walking stick", "available": 20},
    {"name": "Paracetamol tablet", "available": 15},
    {"name": "Oxygen Concentrator", "available": 25},
  ];

  @override
  Widget build(BuildContext context) {
    // Filter items by search
    List<Map<String, dynamic>> filteredItems = availableItems
        .where((item) =>
        item["name"].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Receiver Page"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 16),

            // 📦 List of Items
            if (!showForm)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          "${item["name"]} (Available: ${item["available"]})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            setState(() {
                              showForm = true;
                              selectedItem = item["name"];
                              selectedQuantity = 1;
                            });
                          },
                          child: const Text("Request"),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ✍️ Form Section
            if (showForm)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text("Requesting: $selectedItem",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),

                      // Quantity
                      Row(
                        children: [
                          const Text("Quantity:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.red),
                            onPressed: () {
                              if (selectedQuantity > 1) {
                                setState(() => selectedQuantity--);
                              }
                            },
                          ),
                          Text("$selectedQuantity",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () {
                              setState(() => selectedQuantity++);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Receiver Details
                      _buildInputField("Receiver Name", _nameController),
                      _buildInputField("Phone", _phoneController,
                          keyboardType: TextInputType.phone),
                      _buildInputField("Address", _addressController),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => showForm = false);
                              },
                              child: const Text("Back"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final request = Request(
                                    itemName: selectedItem!,
                                    quantity: selectedQuantity,
                                    available: 1,
                                    receiverName: _nameController.text,
                                    phone: _phoneController.text,
                                    address: _addressController.text,
                                  );
                                  Navigator.pop(context, request);
                                }
                              },
                              child: const Text("Submit Request"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🌿 Custom input field
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
