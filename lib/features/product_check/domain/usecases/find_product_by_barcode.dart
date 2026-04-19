import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';

final class FindProductByBarcode {
  const FindProductByBarcode(this._repository);

  final ProductRepository _repository;

  Future<List<ProductBriefEntity>> call(String barcode) {
    return _repository.findByBarcode(barcode);
  }
}
