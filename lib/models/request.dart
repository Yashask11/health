// lib/models/request.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String receiverUid;
  final String receiverName;
  final String receiverEmail;
  final String receiverPhone;
  final String donorUid;
  final String itemName;
  final String type;
  final String status;
  final String? imageUrl;
  final int? quantity;
  final DateTime? timestamp;

  Request({
    required this.id,
    required this.receiverUid,
    required this.receiverName,
    required this.receiverEmail,
    required this.receiverPhone,
    required this.donorUid,
    required this.itemName,
    required this.type,
    required this.status,
    this.imageUrl,
    this.quantity,
    this.timestamp,
  });

  // Factory constructor to create from Firestore data
  factory Request.fromMap(Map<String, dynamic> data, {String? id}) {
    // Safely parse quantity
    int? parsedQuantity;
    if (data['quantity'] is int) {
      parsedQuantity = data['quantity'] as int;
    } else if (data['quantity'] != null) {
      parsedQuantity = int.tryParse(data['quantity'].toString());
    } else {
      parsedQuantity = null;
    }

    // Safely parse timestamp (Firestore Timestamp -> DateTime)
    DateTime? parsedTimestamp;
    final ts = data['timestamp'];
    if (ts is Timestamp) {
      parsedTimestamp = ts.toDate();
    } else if (ts is String) {
      parsedTimestamp = DateTime.tryParse(ts);
    } else {
      parsedTimestamp = null;
    }

    return Request(
      id: id ?? data['id'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverEmail: data['receiverEmail'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      donorUid: data['donorUid'] ?? '',
      itemName: data['itemName'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'Pending',
      imageUrl: data['imageUrl'],
      quantity: parsedQuantity,
      timestamp: parsedTimestamp,
    );
  }

  // Convert object back to map (timestamp -> Firestore Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'receiverUid': receiverUid,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'receiverPhone': receiverPhone,
      'donorUid': donorUid,
      'itemName': itemName,
      'type': type,
      'status': status,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }
}
