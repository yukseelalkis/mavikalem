class ProductBriefEntity {
  const ProductBriefEntity({
    required this.id,
    required this.name,
    required this.stockCode,
    required this.barcode,
    this.imageUrls = const <String>[],
    required this.stockAmount,
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
}
