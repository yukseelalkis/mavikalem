import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';

abstract interface class ProductRepository {
  Future<List<ProductBriefEntity>> findByBarcode(String barcode);
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode);
}
