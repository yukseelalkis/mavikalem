class ProductModel {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final String brandName;
  final String sku;
  final double stockAmount;
  final String description; // Değişken burada tanımlı

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.brandName,
    required this.sku,
    required this.stockAmount,
    required this.description, // HATA BURADAYDI: Buraya eklememiş olabilirsin
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String imgUrl = "";

    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      final img = json['images'][0];
      final dir = img['directoryName'];
      final file = img['filename'];
      final ext = img['extension'];
      final rev = img['revision'] ?? "";

      // Bir önceki adımda bulduğumuz kesinleşen URL yapısı
      imgUrl =
          "https://www.mavikalem.tr/idea/rf/86/myassets/products/$dir/$file.$ext?revision=$rev";
    }

    return ProductModel(
      id: json['id'],
      name: json['name'] ?? "",
      price: (json['price1'] as num? ?? 0.0).toDouble(),
      brandName: json['brand']?['name'] ?? "Mavi Kalem",
      sku: json['sku'] ?? "",
      stockAmount: (json['stockAmount'] as num? ?? 0.0).toDouble(),
      imageUrl: imgUrl,
      // API'den gelen detay verisini alıyoruz
      description:
          json['details'] != null && (json['details'] as List).isNotEmpty
          ? json['details'][0]['details'] ?? ""
          : "",
    );
  }
}
