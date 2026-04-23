class ProductBriefEntity {
  const ProductBriefEntity({
    required this.id,
    required this.name,
    required this.stockCode,
    required this.barcode,
    this.imageUrls = const <String>[],
    required this.stockAmount,
    this.price,
    this.deliveryTypeRaw,
  });

  final int id;
  final String name;
  final String stockCode;
  final String barcode;

  /// Bos olmayan tum urun gorselleri (API `images` dizisinden).
  final List<String> imageUrls;

  /// Ilk gorsel URL; tek resim / geriye donuk kullanim.
  String get imageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  final double stockAmount;

  /// Liste fiyati (IdeaSoft `price1`); API yoksa null.
  final double? price;
  final String? deliveryTypeRaw;
}
