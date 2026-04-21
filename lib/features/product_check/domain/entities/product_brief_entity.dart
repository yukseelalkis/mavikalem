class ProductBriefEntity {
  const ProductBriefEntity({
    required this.id,
    required this.name,
    required this.stockCode,
    required this.barcode,
    required this.imageUrl,
    required this.stockAmount,
    this.price,
  });

  final int id;
  final String name;
  final String stockCode;
  final String barcode;
  final String imageUrl;
  final double stockAmount;

  /// Liste fiyati (IdeaSoft `price1`); API yoksa null.
  final double? price;
}
