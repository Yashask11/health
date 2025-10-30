import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for user info
import 'package:uuid/uuid.dart';
import 'models/donation.dart';

class DonorForm extends StatefulWidget {
  const DonorForm({super.key});

  @override
  _DonorFormPageState createState() => _DonorFormPageState();
}

class _DonorFormPageState extends State<DonorForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  String _donationType = 'Medicine';
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _pickExpiryDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileId = const Uuid().v4();
      final storageRef =
      FirebaseStorage.instance.ref().child('donation_images/$fileId.jpg');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ⚠️ Validation for Medicine expiry date
    if (_donationType == 'Medicine') {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Please select an expiry date."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      final sixMonthsLater = DateTime.now().add(const Duration(days: 180));
      if (_selectedDate!.isBefore(sixMonthsLater)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⚠️ Please select a date at least 6 months ahead before submitting.",
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ You must be logged in to donate."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('donations').add({
        'donorName': _donorNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'itemName': _itemNameController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'condition':
        _donationType == 'Equipment' ? _conditionController.text : '',
        'type': _donationType,
        'expiryDate': _donationType == 'Medicine'
            ? _selectedDate?.toIso8601String()
            : null,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'donorEmail': currentUser.email, // ✅ store email
        'donorUid': currentUser.uid, // ✅ store UID
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Donation submitted successfully!"),
          backgroundColor: Colors.lightBlue,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving donation: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
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
        title: const Text(
          "Donation Form",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: skyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🧑‍🤝‍🧑 Donor Information",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),

              _buildTextField(
                  _donorNameController, "Full Name", Icons.person, skyBlue),
              _buildTextField(_phoneController, "Phone Number", Icons.phone,
                  skyBlue,
                  keyboardType: TextInputType.phone),
              _buildTextField(
                  _addressController, "Address", Icons.location_on, skyBlue),
              const SizedBox(height: 20),

              const Text(
                "🎁 Donation Type",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Medicine"),
                      value: "Medicine",
                      activeColor: skyBlue,
                      groupValue: _donationType,
                      onChanged: (value) {
                        setState(() => _donationType = value!);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Equipment"),
                      value: "Equipment",
                      activeColor: skyBlue,
                      groupValue: _donationType,
                      onChanged: (value) {
                        setState(() => _donationType = value!);
                      },
                    ),
                  ),
                ],
              ),
              _buildTextField(
                  _itemNameController,
                  _donationType == 'Medicine'
                      ? "Medicine Name"
                      : "Equipment Name",
                  Icons.medical_services,
                  skyBlue),
              _buildTextField(_quantityController, "Quantity", Icons.numbers,
                  skyBlue,
                  keyboardType: TextInputType.number),

              if (_donationType == 'Medicine') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? "No Expiry Date Selected"
                            : "Expiry Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickExpiryDate,
                      child: const Text("Pick Date"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "⚠️ Please select a date at least 6 months ahead before submitting.\n⚠️ Please confirm medicine safety before submitting.",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500),
                ),
              ],

              if (_donationType == 'Equipment')
                _buildTextField(_conditionController, "Condition",
                    Icons.build_circle, skyBlue),

              const SizedBox(height: 25),

              Center(
                child: Column(
                  children: [
                    _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: skyBlue),
                      ),
                      child: const Icon(Icons.image,
                          size: 70, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: skyBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: skyBlue)),
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload Image"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Submit button always visible
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: skyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Submit Donation",
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, Color skyBlue,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (v) => v!.isEmpty ? "Please enter $label" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: skyBlue),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: skyBlue.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: skyBlue, width: 1.5),
          ),
        ),
      ),
    );
  }
}
