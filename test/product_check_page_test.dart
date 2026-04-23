import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';
import 'package:mavikalem_app/features/product_check/domain/usecases/find_product_by_barcode.dart';
import 'package:mavikalem_app/features/product_check/domain/usecases/find_product_by_stock_code.dart';
import 'package:mavikalem_app/features/product_check/presentation/pages/product_check_page.dart';
import 'package:mavikalem_app/features/product_check/presentation/providers/product_check_providers.dart';

ProductBriefEntity _product({
  required int id,
  required String name,
  required String barcode,
  required String stockCode,
}) => ProductBriefEntity(
  id: id,
  name: name,
  stockCode: stockCode,
  barcode: barcode,
  imageUrls: const <String>[],
  stockAmount: 8,
);

final class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository({
    required this.barcodeResultsByQuery,
    this.stockCodeResultsByQuery = const <String, List<ProductBriefEntity>>{},
  });

  final Map<String, List<ProductBriefEntity>> barcodeResultsByQuery;
  final Map<String, List<ProductBriefEntity>> stockCodeResultsByQuery;

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    return barcodeResultsByQuery[barcode] ?? const <ProductBriefEntity>[];
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) async {
    return stockCodeResultsByQuery[stockCode] ?? const <ProductBriefEntity>[];
  }

  @override
  Future<ProductBriefEntity> getById(int productId) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets(
    'shows prefix variants and updates state when suffix 04 is selected',
    (tester) async {
      const scannedPrefix = '6933256616319';
      final variant04 = _product(
        id: 101,
        name: 'Siparis 04',
        barcode: '693325661631904',
        stockCode: 'ORDER-04',
      );
      final variant03 = _product(
        id: 102,
        name: 'Siparis 03',
        barcode: '693325661631903',
        stockCode: 'ORDER-03',
      );
      final variant02 = _product(
        id: 103,
        name: 'Siparis 02',
        barcode: '693325661631902',
        stockCode: 'ORDER-02',
      );

      final fakeRepository = _FakeProductRepository(
        barcodeResultsByQuery: <String, List<ProductBriefEntity>>{
          scannedPrefix: <ProductBriefEntity>[variant04, variant03, variant02],
        },
      );

      final container = ProviderContainer(
        overrides: <Override>[
          findProductByBarcodeProvider.overrideWithValue(
            FindProductByBarcode(fakeRepository),
          ),
          findProductByStockCodeProvider.overrideWithValue(
            FindProductByStockCode(fakeRepository),
          ),
          scannerControllerProvider.overrideWithValue(MobileScannerController()),
        ],
      );
      addTearDown(() async {
        final scanner = container.read(scannerControllerProvider);
        await scanner.dispose();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProductCheckPage()),
        ),
      );

      await tester.enterText(
        find.byType(TextField),
        scannedPrefix,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Ara'));
      await tester.pumpAndSettle();

      expect(find.text('Varyant seçin'), findsOneWidget);
      expect(find.textContaining('693325661631904'), findsWidgets);
      expect(find.textContaining('693325661631903'), findsWidgets);
      expect(find.textContaining('693325661631902'), findsWidgets);

      await tester.tap(find.widgetWithText(ListTile, 'Siparis 04').first);
      await tester.pumpAndSettle();

      expect(find.text('Varyant seçin'), findsNothing);
      expect(find.text('Siparis 04'), findsOneWidget);
      expect(find.text('Siparis 03'), findsNothing);
      expect(find.text('Siparis 02'), findsNothing);

      final selected = container.read(productLookupProvider).requireValue;
      expect(selected, <ProductBriefEntity>[variant04]);
    },
  );
}
