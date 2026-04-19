import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';

/// API bazen filtreyi yok sayip genis liste donebilir; burada yalnizca kullanicinin
/// aradigi stok kodu veya barkoda uyan kalemleri birakilir.
final class ProductQueryFilter {
  const ProductQueryFilter._();

  static List<T> matching<T extends ProductBriefEntity>(
    Iterable<T> products,
    String query,
  ) {
    final q = query.trim();
    if (q.isEmpty) return <T>[];

    final qSku = q.toLowerCase();
    final qBarNorm = _normalizeBarcode(q);

    final seen = <int>{};
    final out = <T>[];

    for (final p in products) {
      if (!seen.add(p.id)) continue;

      final sku = p.stockCode.trim().toLowerCase();
      if (sku == qSku) {
        out.add(p);
        continue;
      }

      final pb = p.barcode.trim();
      if (pb.toLowerCase() == q.toLowerCase()) {
        out.add(p);
        continue;
      }

      final pBarNorm = _normalizeBarcode(pb);
      if (qBarNorm.isNotEmpty &&
          pBarNorm.isNotEmpty &&
          pBarNorm == qBarNorm) {
        out.add(p);
      }
    }

    return out;
  }

  static String _normalizeBarcode(String raw) =>
      raw.replaceAll(RegExp(r'\s'), '');
}
