import 'package:mavikalem_app/features/product_check/data/datasources/product_remote_datasource.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/product_query_filter.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';

final class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    final list = await _remoteDataSource.fetchByBarcode(barcode);
    return ProductQueryFilter.matching(list, barcode);
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
