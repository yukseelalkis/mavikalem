import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';

/// Barkod / stok kodu eslesmesi; sona eklenen 01-99 varyant segmenti icin genisletme.
final class OrderPackMatcher {
  const OrderPackMatcher._();

  static String _normalize(String raw) =>
      raw.replaceAll(RegExp(r'\s'), '').toLowerCase();

  /// Okuyucu / klavye girdisi: trim ve kontrol karakterleri temizligi.
  static String normalizeScanInput(String raw) =>
      raw.trim().replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '');

  /// Bos veya '-' disinda varyant zinciri: her adimda son 2 karakter 01-99 ise kirpilir.
  static Set<String> codeVariants(String raw) {
    final n = _normalize(raw);
    if (n.isEmpty || n == '-') return <String>{};
    final out = <String>{n};
    var s = n;
    while (s.length >= 3) {
      final suf = s.substring(s.length - 2);
      if (!RegExp(r'^(0[1-9]|[1-9][0-9])$').hasMatch(suf)) break;
      s = s.substring(0, s.length - 2);
      out.add(s);
    }
    return out;
  }

  static bool _exactCodeMatchNormalized(OrderItemEntity item, String qNorm) {
    if (qNorm.isEmpty || qNorm == '-') return false;
    final b = _normalize(item.barcode);
    final k = _normalize(item.stockCode);
    return (b.isNotEmpty && b != '-' && b == qNorm) ||
        (k.isNotEmpty && k != '-' && k == qNorm);
  }

  static bool _exactCodeMatch(OrderItemEntity item, String scan) {
    final q = _normalize(scan);
    return _exactCodeMatchNormalized(item, q);
  }

  /// Okutulan kod icin en fazla bir kez 01-99 son eki kirpilir (genis yanlis eslesmeyi azaltir).
  static Set<String> codeVariantsOneStep(String raw) {
    final n = _normalize(raw);
    if (n.isEmpty || n == '-') return <String>{};
    final out = <String>{n};
    if (n.length >= 3) {
      final suf = n.substring(n.length - 2);
      if (RegExp(r'^(0[1-9]|[1-9][0-9])$').hasMatch(suf)) {
        out.add(n.substring(0, n.length - 2));
      }
    }
    return out;
  }

  static bool itemMatchesScan(OrderItemEntity item, String scan) {
    final sv = codeVariants(scan);
    if (sv.isEmpty) return false;
    final bv = codeVariants(item.barcode);
    final kv = codeVariants(item.stockCode);
    return sv.intersection(bv).isNotEmpty || sv.intersection(kv).isNotEmpty;
  }

  /// Eslesen siparis kalemleri (sifir veya birden fazla olabilir).
  static List<OrderItemEntity> matchingLines(
    String scan,
    List<OrderItemEntity> items,
  ) {
    final q = scan.trim();
    if (q.isEmpty) return const <OrderItemEntity>[];

    final seen = <int>{};
    final exact = <OrderItemEntity>[];
    for (final item in items) {
      if (!seen.add(item.id)) continue;
      if (_exactCodeMatch(item, q)) exact.add(item);
    }
    if (exact.isNotEmpty) return exact;

    final seen2 = <int>{};
    final fuzzy = <OrderItemEntity>[];
    for (final item in items) {
      if (!seen2.add(item.id)) continue;
      if (itemMatchesScan(item, q)) fuzzy.add(item);
    }
    return fuzzy;
  }

  /// Siparis toplama: yalnizca bu siparisteki kalemlerle eslesir; sipariste yoksa bos liste.
  /// Tam eslesme once; sonra okuma tarafinda tek adim varyant + kalem tarafinda guvenilir tam varyant zinciri.
  static List<OrderItemEntity> matchingLinesForOrderPack(
    String scan,
    List<OrderItemEntity> items,
  ) {
    final cleaned = normalizeScanInput(scan);
    if (cleaned.isEmpty) return const <OrderItemEntity>[];

    final qNorm = _normalize(cleaned);
    if (qNorm.isEmpty || qNorm == '-') return const <OrderItemEntity>[];

    final seen = <int>{};
    final exact = <OrderItemEntity>[];
    for (final item in items) {
      if (!seen.add(item.id)) continue;
      if (_exactCodeMatchNormalized(item, qNorm)) exact.add(item);
    }
    if (exact.isNotEmpty) return exact;

    final scanVariants = codeVariantsOneStep(cleaned);
    if (scanVariants.isEmpty) return const <OrderItemEntity>[];

    final seen2 = <int>{};
    final fuzzy = <OrderItemEntity>[];
    for (final item in items) {
      if (!seen2.add(item.id)) continue;
      final bv = codeVariants(item.barcode);
      final kv = codeVariants(item.stockCode);
      if (scanVariants.intersection(bv).isNotEmpty ||
          scanVariants.intersection(kv).isNotEmpty) {
        fuzzy.add(item);
      }
    }
    return fuzzy;
  }
}
