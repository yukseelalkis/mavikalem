import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/product_check/data/models/product_brief_model.dart';

void main() {
  group('ProductBriefModel.fromJson', () {
    test('parses price1 from root', () {
      final m = ProductBriefModel.fromJson({
        'id': 42,
        'name': 'Test Urun',
        'sku': 'SKU-1',
        'barcode': '123',
        'stockAmount': 10,
        'price1': 99.5,
        'images': <dynamic>[],
      });
      expect(m.price, 99.5);
      expect(m.stockAmount, 10.0);
    });

    test('parses price1 from nested product', () {
      final m = ProductBriefModel.fromJson({
        'id': 1,
        'name': 'Outer',
        'stockAmount': 2,
        'product': <String, dynamic>{
          'price1': 12.25,
          'sku': 'IN-SKU',
          'barcode': '999',
        },
        'images': <dynamic>[],
      });
      expect(m.price, 12.25);
    });

    test('price null when absent', () {
      final m = ProductBriefModel.fromJson({
        'id': 1,
        'name': 'X',
        'sku': 'S',
        'barcode': 'B',
        'stockAmount': 0,
        'images': <dynamic>[],
      });
      expect(m.price, isNull);
    });
  });
}
