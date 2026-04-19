class ProductBriefEntity {
  const ProductBriefEntity({
    required this.id,
    required this.name,
    required this.stockCode,
    required this.barcode,
    required this.imageUrl,
    required this.stockAmount,
  });

  final int id;
  final String name;
  final String stockCode;
  final String barcode;
  final String imageUrl;
  final double stockAmount;
}
