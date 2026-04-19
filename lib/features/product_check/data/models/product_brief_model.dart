import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';

final class ProductBriefModel extends ProductBriefEntity {
  const ProductBriefModel({
    required super.id,
    required super.name,
    required super.stockCode,
    required super.barcode,
    required super.imageUrl,
    required super.stockAmount,
  });

  factory ProductBriefModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? <dynamic>[];
    final firstImage = images.isNotEmpty
        ? images.first as Map<String, dynamic>?
        : null;
    final imageUrl = firstImage == null
        ? ''
        : 'https://www.mavikalem.tr/idea/rf/86/myassets/products/'
              '${firstImage['directoryName']}/${firstImage['filename']}.${firstImage['extension']}';

    return ProductBriefModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '-') as String,
      stockCode: (json['sku'] ?? json['stockCode'] ?? '-') as String,
      barcode: (json['barcode'] ?? '-') as String,
      imageUrl: imageUrl,
      stockAmount: (json['stockAmount'] as num? ?? 0).toDouble(),
    );
  }
}
