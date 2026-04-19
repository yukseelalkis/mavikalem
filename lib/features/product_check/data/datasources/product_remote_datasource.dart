import 'package:dio/dio.dart';
import 'package:mavikalem_app/core/constants/api_endpoints.dart';
import 'package:mavikalem_app/core/network/api_response_parser.dart';
import 'package:mavikalem_app/features/product_check/data/models/product_brief_model.dart';

final class ProductRemoteDataSource {
  const ProductRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ProductBriefModel>> fetchByBarcode(String barcode) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.products,
      queryParameters: <String, dynamic>{'barcode': barcode, 'limit': 20},
    );
    return _parse(response.data);
  }

  Future<List<ProductBriefModel>> fetchByStockCode(String stockCode) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.products,
      queryParameters: <String, dynamic>{'sku': stockCode, 'limit': 20},
    );
    return _parse(response.data);
  }

  Future<ProductBriefModel> fetchById(int id) async {
    final response = await _dio.get<dynamic>(
      '${ApiEndpoints.products}/$id',
    );
    final raw = response.data;
    Map<String, dynamic> map;
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is Map<String, dynamic>) {
        map = nested;
      } else {
        map = raw;
      }
    } else {
      map = ApiResponseParser.parseMap(raw);
    }
    return ProductBriefModel.fromJson(map);
  }

  List<ProductBriefModel> _parse(dynamic raw) {
    final list = ApiResponseParser.parseList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProductBriefModel.fromJson)
        .toList();
  }
}
