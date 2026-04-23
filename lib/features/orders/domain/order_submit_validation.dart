import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';

/// Submit öncesi miktar doğrulama sonucu.
enum PackQuantityResult {
  /// Okutulan adet beklenenle birebir eşit — devam edilebilir.
  equal,

  /// En az bir kalemde okutulan adet beklenenin altında.
  missing,

  /// En az bir kalemde okutulan adet beklenenin üstünde.
  excess,
}

/// [scanned] map'i `{itemId: scannedQty}` formatındadır.
///
/// Her kalem için beklenen miktarla okutulan miktarı karşılaştırır ve
/// genel sonucu döndürür. Fazla durumu eksik durumuna göre önceliklidir:
/// eğer hem fazla hem eksik kalem varsa [PackQuantityResult.excess] döner.
PackQuantityResult validatePackQuantities(
  Map<int, double> scanned,
  List<OrderItemEntity> items,
) {
  if (items.isEmpty) return PackQuantityResult.equal;

  var hasMissing = false;
  var hasExcess = false;

  for (final item in items) {
    final qty = scanned[item.id] ?? 0;
    if (qty < item.quantity) hasMissing = true;
    if (qty > item.quantity) hasExcess = true;
  }

  if (hasExcess) return PackQuantityResult.excess;
  if (hasMissing) return PackQuantityResult.missing;
  return PackQuantityResult.equal;
}
