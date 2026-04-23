import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  stockAmount: 12,
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
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return barcodeResultsByQuery[barcode] ?? const <ProductBriefEntity>[];
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return stockCodeResultsByQuery[stockCode] ?? const <ProductBriefEntity>[];
  }

  @override
  Future<ProductBriefEntity> getById(int productId) {
    throw UnimplementedError();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('realistic order picking flow with prefix scan simulation', (
    tester,
  ) async {
    const scannedPrefix = '6933256616319';
    final order04 = _product(
      id: 101,
      name: 'Siparis 04 - Kirmizi Kalem',
      barcode: '693325661631904',
      stockCode: 'ORDER-04',
    );
    final order03 = _product(
      id: 102,
      name: 'Siparis 03 - Mavi Kalem',
      barcode: '693325661631903',
      stockCode: 'ORDER-03',
    );
    final order02 = _product(
      id: 103,
      name: 'Siparis 02 - Siyah Kalem',
      barcode: '693325661631902',
      stockCode: 'ORDER-02',
    );

    final fakeRepository = _FakeProductRepository(
      barcodeResultsByQuery: <String, List<ProductBriefEntity>>{
        scannedPrefix: <ProductBriefEntity>[order04, order03, order02],
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
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProductCheckPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Fiziksel scanner'dan gelen prefix verisini mock ediyoruz.
    await container.read(productLookupProvider.notifier).searchByQuery(
      scannedPrefix,
    );
    await tester.pumpAndSettle();

    expect(find.text('Varyant seçin'), findsOneWidget);
    expect(find.textContaining('693325661631904'), findsWidgets);
    expect(find.textContaining('693325661631903'), findsWidgets);
    expect(find.textContaining('693325661631902'), findsWidgets);

    await tester.tap(find.widgetWithText(ListTile, 'Siparis 04 - Kirmizi Kalem'));
    await tester.pumpAndSettle();

    expect(find.text('Varyant seçin'), findsNothing);
    expect(find.text('Siparis 04 - Kirmizi Kalem'), findsOneWidget);
    expect(find.text('Siparis 03 - Mavi Kalem'), findsNothing);
    expect(find.text('Siparis 02 - Siyah Kalem'), findsNothing);
  });
}
