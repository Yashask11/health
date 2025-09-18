import 'dart:io';

/// Enum to differentiate donation type
enum DonationType { medicine, equipment }

class Donation {
  final DonationType type;     // Medicine or Equipment
  final String itemName;
  final int quantity;
  final String donorName;
  final String phone;
  final String address;
  final int available;
  final File? imageFile;

  // Medicine-specific
  final DateTime? expiryDate;
  final bool? isConfirmed;   // checkbox: safe/unopened

  // Equipment-specific
  final String? condition;   // e.g. "Good", "Needs Repair"

  Donation({
    required this.type,
    required this.itemName,
    required this.quantity,
    required this.donorName,
    required this.phone,
    required this.address,
    required this.available,
    this.imageFile,
    this.expiryDate,   // for medicine
    this.isConfirmed,  // for medicine
    this.condition,    // for equipment
  });
}
