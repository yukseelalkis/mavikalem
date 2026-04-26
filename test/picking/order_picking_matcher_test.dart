import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picking_progress.dart';
import 'package:mavikalem_app/features/picking/domain/services/order_picking_matcher.dart';

OrderItemEntity _orderItem({
  required int id,
  required String sku,
  required String barcode,
  required double quantity,
}) {
  return OrderItemEntity(
    id: id,
    productId: id,
    name: 'Item $id',
    stockCode: sku,
    barcode: barcode,
    quantity: quantity,
    unitPrice: 10,
    imageUrl: '',
  );
}

PickedItem _picked({
  required String id,
  required int orderId,
  required String sku,
  required int quantity,
}) {
  final now = DateTime(2026);
  return PickedItem(
    id: id,
    orderId: orderId,
    sku: sku,
    productName: 'Picked $id',
    quantity: quantity,
    updatedAt: now,
  );
}

void main() {
  group('OrderPickingMatcher.combine', () {
    test('returns pending status when no picked items', () {
      final result = OrderPickingMatcher.combine(
        orderId: 1,
        orderItems: <OrderItemEntity>[
          _orderItem(id: 1, sku: 'SKU-1', barcode: 'BAR-1', quantity: 2),
        ],
        pickedItems: const <PickedItem>[],
      );

      expect(result.totalRequired, 2);
      expect(result.totalPicked, 0);
      expect(result.ratio, 0);
      expect(result.lines.single.status, PickedLineStatus.pending);
      expect(result.extraScans, isEmpty);
      expect(result.isComplete, isFalse);
    });

    test('detects partial, completed and excess statuses', () {
      final orderItems = <OrderItemEntity>[
        _orderItem(id: 1, sku: 'sku-a', barcode: 'bar-a', quantity: 2),
        _orderItem(id: 2, sku: 'sku-b', barcode: 'bar-b', quantity: 1),
        _orderItem(id: 3, sku: 'sku-c', barcode: 'bar-c', quantity: 1),
      ];

      final result = OrderPickingMatcher.combine(
        orderId: 99,
        orderItems: orderItems,
        pickedItems: <PickedItem>[
          _picked(id: '1', orderId: 99, sku: 'SKU-A', quantity: 1),
          _picked(id: '2', orderId: 99, sku: 'sku-b', quantity: 1),
          _picked(id: '3', orderId: 99, sku: 'sku-c', quantity: 2),
        ],
      );

      expect(result.lines[0].status, PickedLineStatus.partial);
      expect(result.lines[1].status, PickedLineStatus.completed);
      expect(result.lines[2].status, PickedLineStatus.excess);
      expect(result.totalRequired, 4);
      expect(result.totalPicked, 3);
      expect(result.ratio, 3 / 4);
      expect(result.extraScans, isEmpty);
    });

    test('flags extra scans not matching order items', () {
      final result = OrderPickingMatcher.combine(
        orderId: 50,
        orderItems: <OrderItemEntity>[
          _orderItem(id: 1, sku: 'sku-1', barcode: 'bar-1', quantity: 1),
        ],
        pickedItems: <PickedItem>[
          _picked(id: 'a', orderId: 50, sku: 'sku-1', quantity: 1),
          _picked(id: 'b', orderId: 50, sku: 'unknown', quantity: 1),
        ],
      );

      expect(result.lines.single.status, PickedLineStatus.completed);
      expect(result.extraScans.length, 1);
      expect(result.extraScans.single.sku, 'unknown');
      expect(result.isComplete, isFalse);
    });

    test('normalizes whitespace and case during matching', () {
      final result = OrderPickingMatcher.combine(
        orderId: 12,
        orderItems: <OrderItemEntity>[
          _orderItem(id: 1, sku: 'SKU 123', barcode: 'BAR 123', quantity: 1),
        ],
        pickedItems: <PickedItem>[
          _picked(id: 'a', orderId: 12, sku: 'sku123', quantity: 1),
        ],
      );

      expect(result.lines.single.status, PickedLineStatus.completed);
      expect(result.extraScans, isEmpty);
      expect(result.isComplete, isTrue);
    });
  });
}
