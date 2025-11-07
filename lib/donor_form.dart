import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorFormPage extends StatefulWidget {
  const DonorFormPage({super.key});

  @override
  State<DonorFormPage> createState() => _DonorFormPageState();
}

class _DonorFormPageState extends State<DonorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _itemQuantityController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _conditionController = TextEditingController();
  final _addressController = TextEditingController();

  String _donationType = "Medicine";
  File? _selectedImage;
  String _userUid = "";
  String _userEmail = "";
  String _userName = "";
  String _userPhone = "";

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

    final doc =
    await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists) {
      setState(() {
        _userName = doc['name'] ?? "";
        _userPhone = doc['phone'] ?? "";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("donation_images/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Uploading donation..."),
        backgroundColor: Colors.blue,
      ),
    );

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    try {
      final docRef = FirebaseFirestore.instance.collection("donations").doc();

      await docRef.set({
        'donorUid': _userUid,
        'donorEmail': _userEmail,
        'donorName': _userName,
        'donorPhone': _userPhone,
        'address': _addressController.text.trim(),
        'itemName': _itemNameController.text.trim(),
        'quantity': int.tryParse(_itemQuantityController.text.trim()) ?? 0,
        'available': int.tryParse(_itemQuantityController.text.trim()) ?? 0, // ✅ Fixed line
        'type': _donationType,
        'condition': _donationType == 'Equipment'
            ? _conditionController.text.trim()
            : null,
        'expiryDate': _donationType == 'Medicine'
            ? _expiryDateController.text.trim()
            : null,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Donation added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donation Form"),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: "Item Name"),
                validator: (value) =>
                value!.isEmpty ? "Enter item name" : null,
              ),
              TextFormField(
                controller: _itemQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                validator: (value) =>
                value!.isEmpty ? "Enter quantity" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _donationType,
                decoration: const InputDecoration(labelText: "Donation Type"),
                items: const [
                  DropdownMenuItem(value: "Medicine", child: Text("Medicine")),
                  DropdownMenuItem(value: "Equipment", child: Text("Equipment")),
                ],
                onChanged: (value) {
                  setState(() {
                    _donationType = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_donationType == "Medicine")
                TextFormField(
                  controller: _expiryDateController,
                  decoration:
                  const InputDecoration(labelText: "Expiry Date (YYYY-MM-DD)"),
                  validator: (value) => value!.isEmpty
                      ? "Enter expiry date"
                      : null,
                ),
              if (_donationType == "Equipment")
                TextFormField(
                  controller: _conditionController,
                  decoration:
                  const InputDecoration(labelText: "Condition (Good/New)"),
                  validator: (value) =>
                  value!.isEmpty ? "Enter condition" : null,
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) =>
                value!.isEmpty ? "Enter address" : null,
              ),
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    _selectedImage != null
                        ? Image.file(_selectedImage!,
                        width: 150, height: 150, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 80, color: Colors.grey),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload Image"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text("Submit", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
