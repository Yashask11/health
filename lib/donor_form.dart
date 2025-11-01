// lib/donor_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'models/donation.dart';

class DonorForm extends StatefulWidget {
  const DonorForm({super.key});

  @override
  _DonorFormPageState createState() => _DonorFormPageState();
}

class _DonorFormPageState extends State<DonorForm> {
  final _formKey = GlobalKey<FormState>();

  // donation fields
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemQuantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // hidden (auto-filled) user info
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userUid = "";

  File? _imageFile;
  bool _isSubmitting = false;
  String _donationType = "Medicine"; // Medicine | Equipment

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    _expiryDateController.dispose();
    _conditionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // not logged in - shouldn't normally happen; show placeholder
      setState(() {
        _userUid = "";
        _userEmail = "";
        _userName = "";
        _userPhone = "";
      });
      return;
    }

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
        // fallback to FirebaseAuth values
        setState(() {
          _userName = user.displayName ?? "";
          _userPhone = "";
          _addressController.text = "";
        });
      }
    } catch (e) {
      // ignore - fill from auth
      setState(() {
        _userName = user.displayName ?? "";
        _userPhone = "";
        _addressController.text = "";
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final id = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('donation_images/$id.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _pickExpiryDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 180)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      _expiryDateController.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Medicine-specific checks
    if (_donationType == "Medicine") {
      if (_expiryDateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Please select an expiry date."),
          backgroundColor: Colors.orangeAccent,
        ));
        return;
      }
      // parse expiry date
      try {
        final expiry = DateTime.parse(_expiryDateController.text);
        final sixMonths = DateTime.now().add(const Duration(days: 180));
        if (expiry.isBefore(sixMonths)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("⚠️ Please select a date at least 6 months ahead before submitting."),
            backgroundColor: Colors.orangeAccent,
          ));
          return;
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Invalid expiry date format."),
          backgroundColor: Colors.orangeAccent,
        ));
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_imageFile != null) imageUrl = await _uploadImage(_imageFile!);

      final docRef = FirebaseFirestore.instance.collection('donations').doc();
      await docRef.set({
        'donorUid': _userUid,
        'donorEmail': _userEmail,
        'donorName': _userName,
        'donorPhone': _userPhone,
        'address': _addressController.text.trim(),
        'itemName': _itemNameController.text.trim(),
        'quantity': int.tryParse(_itemQuantityController.text.trim()) ?? 0,
        'type': _donationType,
        'condition': _donationType == 'Equipment' ? _conditionController.text.trim() : null,
        'expiryDate': _donationType == 'Medicine' ? _expiryDateController.text.trim() : null,
        'imageUrl': imageUrl ?? '',
        'available': 1,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("✅ Donation submitted successfully!"),
        backgroundColor: Colors.lightBlue,
      ));

      Navigator.pop(context); // close donor form
    } catch (e) {
      debugPrint("Save donation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error saving donation: $e"),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const skyBlue = Color(0xFF87CEEB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Donation Form", style: TextStyle(color: Colors.black)),
        backgroundColor: skyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Donor info is hidden (we still show the address editable)
              const Text("🧑‍🤝‍🧑 Donor (auto-filled)"),
              const SizedBox(height: 6),
              // Address (editable)
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address (editable)",
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v == null || v.isEmpty ? "Please enter address" : null,
              ),
              const SizedBox(height: 16),

              // Donation type
              const Text("🎁 Donation Type", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Medicine"),
                      value: "Medicine",
                      groupValue: _donationType,
                      onChanged: (v) => setState(() => _donationType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Equipment"),
                      value: "Equipment",
                      groupValue: _donationType,
                      onChanged: (v) => setState(() => _donationType = v!),
                    ),
                  ),
                ],
              ),

              // Item name
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (v) => v == null || v.isEmpty ? "Enter item name" : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _itemQuantityController,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter quantity";
                  if (int.tryParse(v) == null || int.parse(v) <= 0) return "Enter valid quantity";
                  return null;
                },
              ),

              if (_donationType == 'Medicine') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expiryDateController.text.isEmpty
                            ? "No expiry selected"
                            : "Expiry: ${_expiryDateController.text}",
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickExpiryDate,
                      style: ElevatedButton.styleFrom(backgroundColor: skyBlue),
                      child: const Text("Pick Date"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "⚠️ Please select a date at least 6 months ahead before submitting.\n⚠️ Please confirm medicine safety before submitting.",
                  style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
                ),
              ],

              if (_donationType == 'Equipment') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _conditionController,
                  decoration: const InputDecoration(
                    labelText: "Condition (Good/Needs Repair)",
                    prefixIcon: Icon(Icons.build_circle),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    _imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!, height: 150, width: 150, fit: BoxFit.cover),
                    )
                        : Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: skyBlue),
                      ),
                      child: const Icon(Icons.image, size: 70, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: skyBlue,
                        side: BorderSide(color: skyBlue),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: skyBlue),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Donation"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
