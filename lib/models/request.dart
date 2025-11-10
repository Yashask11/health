import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final String receiverUid;
  final String receiverName;
  final String receiverEmail;
  final String receiverPhone;

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

  factory Request.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parsedTimestamp;
    final ts = data['timestamp'];
    if (ts is Timestamp) parsedTimestamp = ts.toDate();
    else if (ts is String) parsedTimestamp = DateTime.tryParse(ts);

    return Request(
      id: id,
      receiverUid: data['receiverUid'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverEmail: data['receiverEmail'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      donorUid: data['donorUid'] ?? '',
      donorName: data['donorName'],
      donorEmail: data['donorEmail'],
      donorPhone: data['donorPhone'],
      donorAddress: data['donorAddress'],
      itemName: data['itemName'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'Pending',
      imageUrl: data['imageUrl'],
      quantity: data['quantity'] is int
          ? data['quantity']
          : int.tryParse(data['quantity']?.toString() ?? ''),
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
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }
}
