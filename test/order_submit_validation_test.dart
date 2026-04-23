import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_submit_validation.dart';

OrderItemEntity _item(int id, double quantity) => OrderItemEntity(
      id: id,
      productId: id,
      name: 'Urun $id',
      stockCode: 'SKU-$id',
      barcode: 'BARCODE$id',
      quantity: quantity,
      unitPrice: 10,
      imageUrl: '',
    );

void main() {
  group('validatePackQuantities', () {
    test('bos items listesi equal doner', () {
      final result = validatePackQuantities(<int, double>{}, <OrderItemEntity>[]);
      expect(result, PackQuantityResult.equal);
    });

    test('hic okutulmamis → missing', () {
      final items = [_item(1, 2), _item(2, 3)];
      final result = validatePackQuantities(<int, double>{}, items);
      expect(result, PackQuantityResult.missing);
    });

    test('tam esit okutma → equal', () {
      final items = [_item(1, 2), _item(2, 3)];
      final scanned = <int, double>{1: 2, 2: 3};
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.equal);
    });

    test('bir kalem eksik → missing', () {
      final items = [_item(1, 2), _item(2, 3)];
      final scanned = <int, double>{1: 2, 2: 2}; // kalem 2 eksik
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.missing);
    });

    test('bir kalem fazla → excess', () {
      final items = [_item(1, 2), _item(2, 3)];
      final scanned = <int, double>{1: 2, 2: 4}; // kalem 2 fazla
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.excess);
    });

    test('bir kalem fazla biri eksik → excess (fazla oncelikli)', () {
      final items = [_item(1, 2), _item(2, 3)];
      final scanned = <int, double>{1: 5, 2: 1}; // 1 fazla, 2 eksik
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.excess);
    });

    test('tum kalemler fazla → excess', () {
      final items = [_item(1, 1), _item(2, 1)];
      final scanned = <int, double>{1: 2, 2: 2};
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.excess);
    });

    test('kesirli miktar tam esit → equal', () {
      final items = [_item(1, 1.5)];
      final scanned = <int, double>{1: 1.5};
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.equal);
    });

    test('kesirli miktar eksik → missing', () {
      final items = [_item(1, 1.5)];
      final scanned = <int, double>{1: 1.0};
      final result = validatePackQuantities(scanned, items);
      expect(result, PackQuantityResult.missing);
    });

    test('map yoksa 0 kabul edilir → missing', () {
      final items = [_item(1, 3)];
      final result = validatePackQuantities(<int, double>{}, items);
      expect(result, PackQuantityResult.missing);
    });
  });
}
