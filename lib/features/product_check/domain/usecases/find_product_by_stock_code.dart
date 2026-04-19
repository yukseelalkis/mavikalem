import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';

final class FindProductByStockCode {
  const FindProductByStockCode(this._repository);

  final ProductRepository _repository;

  Future<List<ProductBriefEntity>> call(String stockCode) {
    return _repository.findByStockCode(stockCode);
  }
}
