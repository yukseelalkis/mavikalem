import 'package:mavikalem_app/features/product_check/data/datasources/product_remote_datasource.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';

final class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) {
    return _remoteDataSource.fetchByBarcode(barcode);
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) {
    return _remoteDataSource.fetchByStockCode(stockCode);
  }
}
