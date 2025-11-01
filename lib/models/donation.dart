import 'dart:io';
import 'package:firebase_database/firebase_database.dart';

enum DonationType { medicine, equipment }

class Donation {
  final DonationType type;
  final String itemName;
  final int quantity;
  final String donorName;
  final String phone;
  final String address;
  final int available;

  final File? imageFile; // local file
  final String? imageBase64; // ✅ base64 string stored in Firebase

  final DateTime? expiryDate;
  final bool? isConfirmed;
  final String? condition;

  Donation({
    required this.type,
    required this.itemName,
    required this.quantity,
    required this.donorName,
    required this.phone,
    required this.address,
    required this.available,
    this.imageFile,
    this.imageBase64,
    this.expiryDate,
    this.isConfirmed,
    this.condition,
  });

  // ✅ Convert Donation → Map (for Firebase upload)
  Map<String, dynamic> toMap() {
    return {
      'type': type.name, // "medicine" or "equipment"
      'itemName': itemName,
      'quantity': quantity,
      'donorName': donorName,
      'phone': phone,
      'address': address,
      'available': available,
      'imageBase64': imageBase64, // ✅ store base64 string
      'expiryDate': expiryDate?.toIso8601String(),
      'isConfirmed': isConfirmed,
      'condition': condition,
    };
  }

  // ✅ Convert Map → Donation (for fetching from Firebase)
  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      type: map['type'] == 'medicine'
          ? DonationType.medicine
          : DonationType.equipment,
      itemName: map['itemName'] ?? '',
      quantity: int.tryParse(map['quantity'].toString()) ?? 0,
      donorName: map['donorName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      available: int.tryParse(map['available'].toString()) ?? 1,
      imageBase64: map['imageBase64'], // ✅ now defined
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'])
          : null,
      isConfirmed: map['isConfirmed'] ?? false,
      condition: map['condition'],
    );
  }

  // ✅ Convert Firebase snapshot → Donation
  factory Donation.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return Donation.fromMap(data);
  }
}
