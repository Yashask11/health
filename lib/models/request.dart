class Request {
  final String itemName;
  final int quantity;
  final String receiverName;
  final String phone;
  final String address;
  final int available;

  // 👇 New fields for categorization
  final String receiverType; // "Individual" or "Organization"
  final String? organizationName; // only for organizations

  Request({
    required this.itemName,
    required this.quantity,
    required this.receiverName,
    required this.phone,
    required this.address,
    required this.available,
    required this.receiverType, // new required field
    this.organizationName, // optional field
  });

  // 🔹 Aliases for UI compatibility (no need to change old UI code)
  String get receiverContact => phone;
  String get receiverAddress => address;
}
