import 'package:mavikalem_app/features/product_check/data/datasources/product_remote_datasource.dart';
import 'package:mavikalem_app/features/product_check/domain/barcode_prefix_matcher.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/product_query_filter.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';

final class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  /// Barkod araması: önce tam eşleşme, yoksa aynı listede prefix, yine boşsa
  /// `barcode_cont/start` ile geniş sorgu yapılıp [BarcodePrefixMatcher] ile
  /// süzülür. Böylece fiziksel tarayıcıdan gelen kök barkod (örn. 8698683001661)
  /// veritabanındaki 2-3 haneli varyant ekli barkodlarla eşleşebilir.
  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    final exactList = await _remoteDataSource.fetchByBarcode(barcode);

    final exact = ProductQueryFilter.matching(exactList, barcode);
    if (exact.isNotEmpty) return exact;

    final inlinePrefix = BarcodePrefixMatcher.filter(exactList, barcode);
    if (inlinePrefix.isNotEmpty) return inlinePrefix;

    final candidates = await _remoteDataSource.fetchByBarcodeCandidates(barcode);
    return BarcodePrefixMatcher.filter(candidates, barcode);
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) async {
    final list = await _remoteDataSource.fetchByStockCode(stockCode);
    return ProductQueryFilter.matching(list, stockCode);
  }

  @override
  Future<ProductBriefEntity> getById(int productId) {
    return _remoteDataSource.fetchById(productId);
  }
}
