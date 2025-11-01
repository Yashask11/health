import 'dart:io';

enum DonationType { medicine, equipment }

class Donation {
  final DonationType type;
  final String itemName;
  final int quantity;
  final String donorName;
  final String donorEmail;
  final String donorUid;
  final String phone;
  final String address;
  final String? condition;
  final DateTime? expiryDate;
  final bool? isConfirmed;
  final int available;

  final File? imageFile; // Local image (not stored in Firestore)
  final String? imageBase64; // ✅ Firestore stores Base64 image

  Donation({
    required this.type,
    required this.itemName,
    required this.quantity,
    required this.donorName,
    required this.donorEmail,
    required this.donorUid,
    required this.phone,
    required this.address,
    this.condition,
    this.expiryDate,
    this.isConfirmed,
    required this.available,
    this.imageFile,
    this.imageBase64,
  });

  // ✅ Convert Donation → Map (for uploading to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'itemName': itemName,
      'quantity': quantity,
      'donorName': donorName,
      'donorEmail': donorEmail,
      'donorUid': donorUid,
      'phone': phone,
      'address': address,
      'condition': condition,
      'expiryDate': expiryDate?.toIso8601String(),
      'isConfirmed': isConfirmed ?? false,
      'available': available,
      'imageBase64': imageBase64,
    };
  }

  // ✅ Convert Firestore data → Donation
  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      type: map['type'] == 'medicine'
          ? DonationType.medicine
          : DonationType.equipment,
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      donorName: map['donorName'] ?? '',
      donorEmail: map['donorEmail'] ?? '',
      donorUid: map['donorUid'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      condition: map['condition'],
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'])
          : null,
      isConfirmed: map['isConfirmed'] ?? false,
      available: map['available'] ?? 1,
      imageBase64: map['imageBase64'],
    );
  }
}
