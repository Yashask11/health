class Request {
  final String itemName;
  final int quantity;
  final String receiverName;
  final String phone;
  final String address;
  final int available;

  Request({
    required this.itemName,
    required this.quantity,
    required this.receiverName,
    required this.phone,
    required this.address,
    required this.available,
  });
}
