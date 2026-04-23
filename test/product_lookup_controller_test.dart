import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';
import 'package:mavikalem_app/features/product_check/domain/usecases/find_product_by_barcode.dart';
import 'package:mavikalem_app/features/product_check/domain/usecases/find_product_by_stock_code.dart';
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
  stockAmount: 10,
);

final class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository({
    required this.barcodeResultsByQuery,
    this.stockCodeResultsByQuery = const <String, List<ProductBriefEntity>>{},
  });

  final Map<String, List<ProductBriefEntity>> barcodeResultsByQuery;
  final Map<String, List<ProductBriefEntity>> stockCodeResultsByQuery;

  final List<String> barcodeCalls = <String>[];
  final List<String> stockCodeCalls = <String>[];

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    barcodeCalls.add(barcode);
    return barcodeResultsByQuery[barcode] ?? const <ProductBriefEntity>[];
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) async {
    stockCodeCalls.add(stockCode);
    return stockCodeResultsByQuery[stockCode] ?? const <ProductBriefEntity>[];
  }

  @override
  Future<ProductBriefEntity> getById(int productId) {
    throw UnimplementedError();
  }
}

void main() {
  group('ProductLookupController.searchByQuery', () {
    test(
      'filters and keeps prefix variants, then narrows to selected suffix',
      () async {
        const scannedPrefix = '6933256616319';
        final variant04 = _product(
          id: 1,
          name: 'Siparis 04',
          barcode: '693325661631904',
          stockCode: 'ORDER-04',
        );
        final variant03 = _product(
          id: 2,
          name: 'Siparis 03',
          barcode: '693325661631903',
          stockCode: 'ORDER-03',
        );
        final variant02 = _product(
          id: 3,
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
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(productLookupProvider.notifier);

        await notifier.searchByQuery(scannedPrefix);

        final listed = container.read(productLookupProvider).requireValue;
        expect(listed.map((p) => p.barcode), <String>[
          '693325661631904',
          '693325661631903',
          '693325661631902',
        ]);
        expect(fakeRepository.stockCodeCalls, <String>[scannedPrefix]);
        expect(fakeRepository.barcodeCalls, <String>[scannedPrefix]);

        notifier.selectSingleProduct(variant04);

        final selected = container.read(productLookupProvider).requireValue;
        expect(selected, <ProductBriefEntity>[variant04]);
      },
    );
  });
}
