// lib/models/request.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String receiverUid;
  final String receiverName;
  final String receiverEmail;
  final String receiverPhone;

  // donor details included so receiver can see donor info later
  final String donorUid;
  final String? donorName;
  final String? donorEmail;
  final String? donorPhone;
  final String? donorAddress;

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
    this.donorName,
    this.donorEmail,
    this.donorPhone,
    this.donorAddress,
    required this.itemName,
    required this.type,
    required this.status,
    this.imageUrl,
    this.quantity,
    this.timestamp,
  });

  factory Request.fromMap(Map<String, dynamic> data, {String? id}) {
    int? parsedQuantity;
    if (data['quantity'] is int) {
      parsedQuantity = data['quantity'] as int;
    } else if (data['quantity'] != null) {
      parsedQuantity = int.tryParse(data['quantity'].toString());
    }

    DateTime? parsedTimestamp;
    final ts = data['timestamp'];
    if (ts is Timestamp) {
      parsedTimestamp = ts.toDate();
    } else if (ts is String) {
      parsedTimestamp = DateTime.tryParse(ts);
    }

    return Request(
      id: id ?? (data['id'] ?? '') as String,
      receiverUid: (data['receiverUid'] ?? '') as String,
      receiverName: (data['receiverName'] ?? '') as String,
      receiverEmail: (data['receiverEmail'] ?? '') as String,
      receiverPhone: (data['receiverPhone'] ?? '') as String,
      donorUid: (data['donorUid'] ?? '') as String,
      donorName: data['donorName'] != null ? data['donorName'].toString() : null,
      donorEmail: data['donorEmail'] != null ? data['donorEmail'].toString() : null,
      donorPhone: data['donorPhone'] != null ? data['donorPhone'].toString() : null,
      donorAddress: data['donorAddress'] != null ? data['donorAddress'].toString() : null,
      itemName: (data['itemName'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      status: (data['status'] ?? 'Pending') as String,
      imageUrl: data['imageUrl'] != null ? data['imageUrl'].toString() : null,
      quantity: parsedQuantity,
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiverUid': receiverUid,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'receiverPhone': receiverPhone,
      'donorUid': donorUid,
      'donorName': donorName,
      'donorEmail': donorEmail,
      'donorPhone': donorPhone,
      'donorAddress': donorAddress,
      'itemName': itemName,
      'type': type,
      'status': status,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }
}
