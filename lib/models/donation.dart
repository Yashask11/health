import 'dart:io';

class Donation {
  final String itemName;
  final int quantity;
  final String expiryDate;
  final String donorName;
  final String phone;
  final String address;   // 👈 added
  final int available;    // 👈 added
  final File? imageFile;  // 👈 optional

  Donation({
    required this.itemName,
    required this.quantity,
    required this.expiryDate,
    required this.donorName,
    required this.phone,
    required this.address,
    required this.available,
    this.imageFile,
  });
}
