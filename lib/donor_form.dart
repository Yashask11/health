import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/donation.dart';

class DonorForm extends StatefulWidget {
  const DonorForm({super.key});

  @override
  _DonorFormPageState createState() => _DonorFormPageState();
}

class _DonorFormPageState extends State<DonorForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemQuantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  File? _imageFile;
  bool _isAgreed = false;
  DonationType _selectedType = DonationType.medicine; // default medicine

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 180)),
      firstDate: now.add(const Duration(days: 180)),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _expiryDateController.text =
        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == DonationType.medicine && !_isAgreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text("⚠️ Please confirm medicine safety before submitting."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final donation = Donation(
        type: _selectedType,
        itemName: _itemNameController.text,
        quantity: int.tryParse(_itemQuantityController.text) ?? 0,
        donorName: _donorNameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        available: 1,
        imageFile: _imageFile,
        expiryDate: _selectedType == DonationType.medicine
            ? DateTime.tryParse(_expiryDateController.text)
            : null,
        isConfirmed: _selectedType == DonationType.medicine ? _isAgreed : null,
        condition:
        _selectedType == DonationType.equipment ? _conditionController.text : null,
      );

      Navigator.pop(context, donation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Form"),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFBBDEFB), // very light blue background
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<DonationType>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: "Donation Type",
                              labelStyle: const TextStyle(color: Colors.black),
                              prefixIcon:
                              const Icon(Icons.category, color: Colors.black),
                              filled: true,
                              fillColor: Colors.white, // white block
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: DonationType.medicine,
                                child: Text("Medicine"),
                              ),
                              DropdownMenuItem(
                                value: DonationType.equipment,
                                child: Text("Equipment"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _itemNameController,
                            label: "Item Name",
                            icon: Icons.shopping_bag,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _itemQuantityController,
                            label: "Item Quantity",
                            icon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter Item Quantity";
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return "Quantity must be greater than 0";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_selectedType == DonationType.medicine) ...[
                            GestureDetector(
                              onTap: _pickExpiryDate,
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  controller: _expiryDateController,
                                  label: "Expiry Date",
                                  icon: Icons.calendar_today,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "⚠️ Please select a date at least 6 months ahead.",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12),
                              ),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isAgreed,
                                  activeColor: Colors.blueAccent,
                                  checkColor: Colors.white,
                                  onChanged: (value) {
                                    setState(() {
                                      _isAgreed = value ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    "I confirm this medicine is unopened and safe.",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (_selectedType == DonationType.equipment) ...[
                            _buildTextField(
                              controller: _conditionController,
                              label: "Condition (Good / Needs Repair)",
                              icon: Icons.build,
                            ),
                          ],

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _donorNameController,
                            label: "Donor Name",
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: "Phone Number",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter Phone Number";
                              }
                              if (value.length < 10) {
                                return "Enter a valid phone number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: "Address",
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text("Pick Image"),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _imageFile != null
                                    ? Image.file(
                                  _imageFile!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                )
                                    : Image.asset(
                                  "assets/dumy.jpg",
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              elevation: 6,
                            ),
                            onPressed: _submitForm,
                            child: const Text(
                              "Submit",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white, // solid white block
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      validator: validator ??
              (value) => value == null || value.isEmpty ? "Enter $label" : null,
    );
  }
}
