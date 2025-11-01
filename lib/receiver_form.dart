// lib/receiver_form.dart  (or replace your existing receiver_page.dart content)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/request.dart';

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({super.key});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final _formKey = GlobalKey<FormState>();

  // only address & organization are shown; name/phone/email are hidden (auto-filled)
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();

  // quantity/item selection state
  String? selectedItem;
  int selectedQuantity = 1;
  bool showForm = false;
  String searchQuery = "";

  // receiver type: Individual | Organization
  String receiverType = "Individual";

  // auto-filled hidden fields
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userUid = "";

  final List<Map<String, dynamic>> availableItems = [
    {"name": "Wheelchair", "available": 10},
    {"name": "Walking stick", "available": 20},
    {"name": "Paracetamol tablet", "available": 15},
    {"name": "Oxygen Concentrator", "available": 25},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userUid = user.uid;
    _userEmail = user.email ?? "";

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = (data['name'] ?? user.displayName ?? "").toString();
          _userPhone = (data['phone'] ?? "").toString();
          _addressController.text = (data['address'] ?? "").toString();
        });
      } else {
        setState(() {
          _userName = user.displayName ?? "";
          _userPhone = "";
          _addressController.text = "";
        });
      }
    } catch (e) {
      setState(() {
        _userName = user.displayName ?? "";
        _userPhone = "";
      });
    }
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    final request = Request(
      itemName: selectedItem ?? "",
      quantity: selectedQuantity,
      available: 1,
      receiverName: _userName,
      phone: _userPhone,
      address: _addressController.text.trim(),
      receiverType: receiverType,
      organizationName: receiverType == "Organization" ? _organizationController.text.trim() : null,
    );

    // optionally save to Firestore as well:
    // save to 'requests' collection with user info
    FirebaseFirestore.instance.collection('requests').add({
      'itemName': request.itemName,
      'quantity': request.quantity,
      'available': request.available,
      'receiverName': request.receiverName,
      'phone': request.phone,
      'address': request.address,
      'receiverType': request.receiverType,
      'organizationName': request.organizationName ?? '',
      'requesterUid': _userUid,
      'requesterEmail': _userEmail,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context, request);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = availableItems.where((it) {
      final name = (it['name'] ?? "").toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

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
            TextField(
              decoration: const InputDecoration(
                hintText: "Search items...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
            const SizedBox(height: 16),

            if (!showForm)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, idx) {
                    final it = filteredItems[idx];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text("${it['name']} (Available: ${it['available']})",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            setState(() {
                              showForm = true;
                              selectedItem = it['name'];
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

            if (showForm)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text("Requesting: $selectedItem", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Text("Quantity:", style: TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.red),
                            onPressed: () {
                              if (selectedQuantity > 1) setState(() => selectedQuantity--);
                            },
                          ),
                          Text("$selectedQuantity", style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () => setState(() => selectedQuantity++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text("Receiver Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Individual"),
                              value: "Individual",
                              groupValue: receiverType,
                              onChanged: (v) => setState(() => receiverType = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Organization"),
                              value: "Organization",
                              groupValue: receiverType,
                              onChanged: (v) => setState(() => receiverType = v!),
                            ),
                          ),
                        ],
                      ),

                      if (receiverType == "Organization")
                        TextFormField(
                          controller: _organizationController,
                          decoration: const InputDecoration(labelText: "Organization Name"),
                          validator: (v) {
                            if (receiverType == "Organization" && (v == null || v.isEmpty)) return "Enter organization name";
                            return null;
                          },
                        ),

                      const SizedBox(height: 12),

                      // Name/Phone/Email are hidden (auto-filled) — we only show and allow editing of address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: "Address (editable)"),
                        validator: (v) => v == null || v.isEmpty ? "Enter address" : null,
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                              onPressed: () => setState(() => showForm = false),
                              child: const Text("Back"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                              onPressed: _submitRequest,
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
}
