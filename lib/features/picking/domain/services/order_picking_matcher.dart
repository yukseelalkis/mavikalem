import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picking_progress.dart';

final class OrderPickingMatcher {
  const OrderPickingMatcher._();

  static PickingProgress combine({
    required int orderId,
    required List<OrderItemEntity> orderItems,
    required List<PickedItem> pickedItems,
  }) {
    final pickedByKey = <String, PickedItem>{
      for (final item in pickedItems)
        if (_normalize(item.sku).isNotEmpty) _normalize(item.sku): item,
    };

    final usedPickedKeys = <String>{};
    final lineProgress = <PickedLineProgress>[];

    var totalRequired = 0;
    var totalPicked = 0;

    for (final orderItem in orderItems) {
      final requiredQty = orderItem.quantity.ceil();
      final lookupCandidates = <String>[
        _normalize(orderItem.stockCode),
      ].where((e) => e.isNotEmpty).toList(growable: false);

      PickedItem? matched;
      String? matchedKey;
      for (final candidate in lookupCandidates) {
        final picked = pickedByKey[candidate];
        if (picked != null) {
          matched = picked;
          matchedKey = candidate;
          break;
        }
      }

      if (matchedKey != null) {
        usedPickedKeys.add(matchedKey);
      }

      final pickedQty = matched?.quantity ?? 0;
      final status = _resolveStatus(
        requiredQty: requiredQty,
        pickedQty: pickedQty,
      );

      totalRequired += requiredQty;
      totalPicked += pickedQty > requiredQty ? requiredQty : pickedQty;

      lineProgress.add(
        PickedLineProgress(
          orderItem: orderItem,
          requiredQuantity: requiredQty,
          pickedQuantity: pickedQty,
          status: status,
          matchedItem: matched,
        ),
      );
    }

    final extraScans = pickedByKey.entries
        .where((entry) => !usedPickedKeys.contains(entry.key))
        .map((entry) => entry.value)
        .toList(growable: false);

    final ratio = totalRequired == 0 ? 0.0 : totalPicked / totalRequired;
    final isComplete =
        lineProgress.every(
          (line) => line.status == PickedLineStatus.completed,
        ) &&
        extraScans.isEmpty;

    return PickingProgress(
      orderId: orderId,
      lines: lineProgress,
      extraScans: extraScans,
      totalRequired: totalRequired,
      totalPicked: totalPicked,
      ratio: ratio,
      isComplete: isComplete,
    );
  }

  static PickedLineStatus _resolveStatus({
    required int requiredQty,
    required int pickedQty,
  }) {
    if (pickedQty <= 0) return PickedLineStatus.pending;
    if (pickedQty < requiredQty) return PickedLineStatus.partial;
    if (pickedQty == requiredQty) return PickedLineStatus.completed;
    return PickedLineStatus.excess;
  }

  static String _normalize(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
