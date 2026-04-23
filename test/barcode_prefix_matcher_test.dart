import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/product_check/domain/barcode_prefix_matcher.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';

ProductBriefEntity _entity(int id, String barcode) => ProductBriefEntity(
  id: id,
  name: 'Product $id',
  stockCode: 'SKU-$id',
  barcode: barcode,
  imageUrls: const [],
  stockAmount: 0,
);

void main() {
  group('BarcodePrefixMatcher.filter', () {
    final products = [
      _entity(1, '869868300166101'),
      _entity(2, '869868300166102'),
      _entity(3, '879999999999'),
      _entity(4, '86986830016619999'),
    ];

    test('matches variants that share the scanned root', () {
      final matches = BarcodePrefixMatcher.filter(products, '8698683001661');

      expect(matches.map((p) => p.id), [1, 2]);
    });

    test('excludes candidates with a different prefix', () {
      final matches = BarcodePrefixMatcher.filter(products, '8698683001661');

      expect(matches.any((p) => p.id == 3), isFalse);
    });

    test('excludes candidates exceeding the length guard', () {
      final matches = BarcodePrefixMatcher.filter(products, '8698683001661');

      expect(matches.any((p) => p.id == 4), isFalse);
    });

    test('returns the exact match when barcodes are identical', () {
      final matches = BarcodePrefixMatcher.filter(products, '869868300166101');

      expect(matches.single.id, 1);
    });

    test('returns empty for blank input', () {
      expect(BarcodePrefixMatcher.filter(products, '   '), isEmpty);
    });

    test('ignores empty and placeholder barcodes', () {
      final items = [
        _entity(10, ''),
        _entity(11, '-'),
        _entity(12, '869868300166101'),
      ];

      final matches = BarcodePrefixMatcher.filter(items, '8698683001661');

      expect(matches.map((p) => p.id), [12]);
    });

    test('respects custom maxExtraDigits override', () {
      final stricter = BarcodePrefixMatcher.filter(
        products,
        '8698683001661',
        maxExtraDigits: 1,
      );

      expect(stricter, isEmpty);
    });
  });
}
