import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationType { medicine, equipment }

class Donation {
  final String id;
  final String itemName;
  final int quantity;
  final DonationType type;
  final String donorName;
  final String donorPhone;
  final String address;
  final bool available;
  final String? imageUrl;
  final DateTime? expiryDate;
  final String? condition;
  final String donorUid; // ✅ ensures ownership tracking
  final Timestamp? timestamp; // ✅ for sorting

  Donation({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.type,
    required this.donorName,
    required this.donorPhone,
    required this.address,
    required this.available,
    this.imageUrl,
    this.expiryDate,
    this.condition,
    required this.donorUid,
    this.timestamp,
  });

  factory Donation.fromMap(String id, Map<String, dynamic> data) {
    return Donation(
      id: id,
      itemName: data['itemName'] ?? '',
      quantity: data['quantity'] is int
          ? data['quantity']
          : int.tryParse(data['quantity']?.toString() ?? '0') ?? 0,
      type: data['type'] == 'equipment'
          ? DonationType.equipment
          : DonationType.medicine,
      donorName: data['donorName'] ?? '',
      donorPhone: data['donorPhone'] ?? '',
      address: data['address'] ?? '',
      available: data['available'] is bool
          ? data['available']
          : (data['available'].toString() == 'true'),
      imageUrl: data['imageUrl'],
      expiryDate: data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : data['expiryDate'] is String
          ? DateTime.tryParse(data['expiryDate'])
          : null,
      condition: data['condition'],
      donorUid: data['donorUid'] ?? '',
      timestamp: data['timestamp'] is Timestamp ? data['timestamp'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'type': type == DonationType.medicine ? 'medicine' : 'equipment',
      'donorName': donorName,
      'donorPhone': donorPhone,
      'address': address,
      'available': available,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'condition': condition,
      'donorUid': donorUid,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }
}
