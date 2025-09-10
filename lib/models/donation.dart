import 'dart:io';

class Donation {
  final String itemName;
  final int quantity;
  final String expiryDate;
  final String donorName;
  final String phone;
  final File? imageFile; // 👈 added

  Donation({
    required this.itemName,
    required this.quantity,
    required this.expiryDate,
    required this.donorName,
    required this.phone,
    this.imageFile,
  });
}
