import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mavikalem_app/core/di/providers.dart';
import 'package:mavikalem_app/features/product_check/data/datasources/product_remote_datasource.dart';
import 'package:mavikalem_app/features/product_check/data/repositories/product_repository_impl.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';
import 'package:mavikalem_app/features/product_check/domain/usecases/find_product_by_barcode.dart';
import 'package:mavikalem_app/features/product_check/domain/usecases/find_product_by_stock_code.dart';

final scannerControllerProvider = Provider<MobileScannerController>(
  (ref) => MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  ),
);

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return ProductRemoteDataSource(dio);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remote = ref.watch(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(remote);
});

/// Siparis kalemi icin GET /products/{id} — Riverpod family onbellek + goruntu icin CachedNetworkImage.
final productBriefByIdProvider =
    FutureProvider.family<ProductBriefEntity, int>((ref, productId) async {
      final repo = ref.watch(productRepositoryProvider);
      return repo.getById(productId);
    });

final findProductByBarcodeProvider = Provider<FindProductByBarcode>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return FindProductByBarcode(repository);
});

final findProductByStockCodeProvider = Provider<FindProductByStockCode>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return FindProductByStockCode(repository);
});

final productLookupProvider =
    AutoDisposeAsyncNotifierProvider<
      ProductLookupController,
      List<ProductBriefEntity>
    >(ProductLookupController.new);

final class ProductLookupController
    extends AutoDisposeAsyncNotifier<List<ProductBriefEntity>> {
  @override
  Future<List<ProductBriefEntity>> build() async {
    return const <ProductBriefEntity>[];
  }

  Future<void> searchByBarcode(String barcode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(findProductByBarcodeProvider);
      return useCase(barcode.trim());
    });
  }

  Future<void> searchByStockCode(String stockCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(findProductByStockCodeProvider);
      return useCase(stockCode.trim());
    });
  }

  /// Manuel arama: once stok kodu (sku), sonuc yoksa barkod — ikisi de repository
  /// icinde girilen metne tam eslesen kayitlarla sinirlanir (API tum listeyi
  /// dondurse bile filtrelenir).
  Future<void> searchByQuery(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final bySku = await ref.read(findProductByStockCodeProvider)(query);
      if (bySku.isNotEmpty) return bySku;

      return ref.read(findProductByBarcodeProvider)(query);
    });
  }
}
