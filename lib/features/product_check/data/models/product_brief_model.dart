import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';

final class ProductBriefModel extends ProductBriefEntity {
  const ProductBriefModel({
    required super.id,
    required super.name,
    required super.stockCode,
    required super.barcode,
    required super.imageUrls,
    required super.stockAmount,
  });

  factory ProductBriefModel.fromJson(Map<String, dynamic> json) {
    final nested = json['product'];
    final nestedMap =
        nested is Map<String, dynamic> ? nested : null;

    var stock = _firstNonEmptyString(json, const [
      'sku',
      'stockCode',
      'productSku',
      'stock_code',
      'product_sku',
    ]);
    var bar = _firstNonEmptyString(json, const [
      'barcode',
      'productBarcode',
      'product_barcode',
      'barCode',
      'ean',
      'gtin',
      'ean13',
      'eanCode',
    ]);

    if (nestedMap != null) {
      stock ??= _firstNonEmptyString(nestedMap, const [
        'sku',
        'stockCode',
        'productSku',
      ]);
      bar ??= _firstNonEmptyString(nestedMap, const [
        'barcode',
        'productBarcode',
        'ean',
        'gtin',
      ]);
    }

    final stockOut = stock ?? '-';
    final barOut = bar ?? '-';

    final stockAmt =
        _readNum(json, const ['stockAmount', 'stock', 'quantity']) ??
        (nestedMap != null
            ? _readNum(nestedMap, const ['stockAmount', 'stock'])
            : null) ??
        0;

    var urls = _collectImageUrls(json);
    if (urls.isEmpty && nestedMap != null) {
      urls = _collectImageUrls(nestedMap);
    }

    return ProductBriefModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name:
          (json['name'] ?? json['productName'] ?? json['title'] ?? '-')
              .toString(),
      stockCode: stockOut,
      barcode: barOut,
      imageUrls: urls,
      stockAmount: stockAmt.toDouble(),
    );
  }

  static const String _productImageBase =
      'https://www.mavikalem.tr/idea/rf/86/myassets/products/';

  static List<String> _collectImageUrls(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? <dynamic>[];
    final out = <String>[];

    for (final raw in images) {
      if (raw is! Map<String, dynamic>) continue;
      final dir = raw['directoryName']?.toString().trim();
      final fn = raw['filename']?.toString().trim();
      final ext = raw['extension']?.toString().trim();
      if (dir == null || fn == null || ext == null) continue;
      if (dir.isEmpty || fn.isEmpty || ext.isEmpty) continue;
      out.add('$_productImageBase$dir/$fn.$ext');
    }

    if (out.isEmpty) {
      final direct = json['imageUrl'] ?? json['image'];
      if (direct != null) {
        final s = direct.toString().trim();
        if (s.isNotEmpty && s != '-') {
          out.add(s);
        }
      }
    }

    return out;
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != '-') return s;
    }
    return null;
  }

  static num? _readNum(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is num) return v;
    }
    return null;
  }
}
