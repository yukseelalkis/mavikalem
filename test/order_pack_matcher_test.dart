import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_pack_matcher.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_bucket.dart';

OrderItemEntity _line({
  required int id,
  required String barcode,
  required String stockCode,
}) {
  return OrderItemEntity(
    id: id,
    productId: id,
    name: 'Urun $id',
    stockCode: stockCode,
    barcode: barcode,
    quantity: 1,
    unitPrice: 10,
    imageUrl: '',
  );
}

void main() {
  group('OrderPackMatcher', () {
    test('exact barcode match', () {
      final items = [
        _line(id: 1, barcode: 'COLORBK01', stockCode: 'SKU-A'),
        _line(id: 2, barcode: 'COLORBK02', stockCode: 'SKU-B'),
      ];
      final m = OrderPackMatcher.matchingLines('COLORBK01', items);
      expect(m.length, 1);
      expect(m.first.id, 1);
    });

    test('variant suffix 01 resolves single line', () {
      final items = [
        _line(id: 1, barcode: 'COLORBK01', stockCode: 'X'),
      ];
      final m = OrderPackMatcher.matchingLines('COLORBK0101', items);
      expect(m.length, 1);
      expect(m.first.id, 1);
    });

    test('ambiguous variant returns multiple lines', () {
      final items = [
        _line(id: 1, barcode: 'COLORBK01', stockCode: 'A'),
        _line(id: 2, barcode: 'COLORBK02', stockCode: 'B'),
      ];
      final m = OrderPackMatcher.matchingLines('COLORBK', items);
      expect(m.length, 2);
    });

    test('stock code match', () {
      final items = [
        _line(id: 1, barcode: '-', stockCode: 'ST-01'),
      ];
      final m = OrderPackMatcher.matchingLines('ST-01', items);
      expect(m.length, 1);
    });
  });

  group('OrderPackMatcher.matchingLinesForOrderPack', () {
    test('sipariste olmayan barkod bos doner', () {
      final items = [
        _line(id: 1, barcode: 'COLORBK01', stockCode: 'SKU-A'),
      ];
      final m = OrderPackMatcher.matchingLinesForOrderPack('YANLISBARKOD', items);
      expect(m, isEmpty);
    });

    test('siparis kalemiyle ayni eslesmeler', () {
      final items = [
        _line(id: 1, barcode: 'COLORBK01', stockCode: 'SKU-A'),
        _line(id: 2, barcode: 'COLORBK02', stockCode: 'SKU-B'),
      ];
      expect(
        OrderPackMatcher.matchingLinesForOrderPack('COLORBK01', items).length,
        1,
      );
      expect(
        OrderPackMatcher.matchingLinesForOrderPack('COLORBK', items).length,
        2,
      );
    });

    test('normalizeScanInput kontrol karakterlerini kirpar', () {
      expect(OrderPackMatcher.normalizeScanInput('  AB\r\n'), 'AB');
    });
  });

  group('OrderStatusBucket', () {
    test('bucketForRawStatus maps common strings', () {
      expect(
        OrderStatusBucket.bucketForRawStatus('Tamamlandi'),
        OrderStatusBucket.tamamlandi,
      );
      expect(
        OrderStatusBucket.bucketForRawStatus('Hazirlaniyor'),
        OrderStatusBucket.hazirlaniyor,
      );
      expect(
        OrderStatusBucket.bucketForRawStatus('Yeni siparis'),
        OrderStatusBucket.yeni,
      );
    });

    test('matches respects all filter', () {
      expect(
        OrderStatusBucket.all.matches(OrderStatusBucket.diger),
        isTrue,
      );
      expect(
        OrderStatusBucket.yeni.matches(OrderStatusBucket.yeni),
        isTrue,
      );
      expect(
        OrderStatusBucket.yeni.matches(OrderStatusBucket.tamamlandi),
        isFalse,
      );
    });
  });
}
