class PickedItem {
  const PickedItem({
    required this.id,
    required this.orderId,
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.updatedAt,
  });

  final String id;
  final int orderId;
  final String sku;
  final String productName;
  final int quantity;
  final DateTime updatedAt;
}
