import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';

/// Varyantlı barkod eşleştirme politikası.
///
/// Fiziksel tarayıcı genelde kök EAN-13 dönerken sistemdeki varyantlı ürünler
/// kök barkodun sonuna 2-3 haneli varyant eki alır. Sayısal karşılaştırma yerine
/// string prefix + uzunluk üst sınırı kullanılır.
final class BarcodeMatchConfig {
  const BarcodeMatchConfig._();

  /// `barcode.length <= scanned.length + maxExtraDigits` üst sınırı.
  static const int maxExtraDigits = 3;
}

/// Taranan koda kök prefix olarak uyan ürünleri süzer; sıralama korunur.
final class BarcodePrefixMatcher {
  const BarcodePrefixMatcher._();

  static List<T> filter<T extends ProductBriefEntity>(
    Iterable<T> candidates,
    String scannedCode, {
    int maxExtraDigits = BarcodeMatchConfig.maxExtraDigits,
  }) {
    final scanned = _normalize(scannedCode);
    if (scanned.isEmpty) return <T>[];

    final maxLen = scanned.length + maxExtraDigits;

    final seen = <int>{};
    final out = <T>[];
    for (final product in candidates) {
      if (!seen.add(product.id)) continue;

      final barcode = _normalize(product.barcode);
      if (barcode.isEmpty || barcode == '-') continue;

      if (!barcode.startsWith(scanned)) continue;
      if (barcode.length > maxLen) continue;

      out.add(product);
    }
    return out;
  }

  static String _normalize(String raw) => raw.replaceAll(RegExp(r'\s'), '').trim();
}
