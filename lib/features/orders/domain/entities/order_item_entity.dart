class OrderItemEntity {
  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.name,
    required this.stockCode,
    required this.quantity,
    required this.unitPrice,
    required this.imageUrl,
  });

  final int id;
  final int productId;
  final String name;
  final String stockCode;
  final double quantity;
  final double unitPrice;
  final String imageUrl;
}
