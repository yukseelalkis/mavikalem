import 'package:dio/dio.dart';
import 'package:mavikalem_app/core/constants/api_endpoints.dart';
import 'package:mavikalem_app/core/network/api_response_parser.dart';
import 'package:mavikalem_app/features/product_check/data/models/product_brief_model.dart';

final class ProductRemoteDataSource {
  const ProductRemoteDataSource(this._dio);

  final Dio _dio;

  static const int _searchLimit = 20;

  /// IdeaSoft `q[barcode_cont]` her zaman mevcut olmayabilir; cevap boşsa
  /// `q[barcode_start]` da denenir. Varyant köklü barkodları bulmak için
  /// kullanılır; döndürülen listede [BarcodePrefixMatcher] ile süzme yapılır.
  static const List<String> _candidateQueryKeys = <String>[
    'q[barcode_cont]',
    'q[barcode_start]',
  ];

  /// GET /api/products?q[barcode]={query}
  Future<List<ProductBriefModel>> fetchByBarcode(String barcode) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.products,
      queryParameters: <String, dynamic>{
        'q[barcode]': barcode.trim(),
        'limit': _searchLimit,
      },
    );
    return _parse(response.data);
  }

  /// Varyantlı barkodları yakalamak için geniş arama: önce `barcode_cont`,
  /// boşsa `barcode_start` denenir.
  Future<List<ProductBriefModel>> fetchByBarcodeCandidates(
    String barcodePrefix,
  ) async {
    final trimmed = barcodePrefix.trim();
    if (trimmed.isEmpty) return const <ProductBriefModel>[];

    for (final key in _candidateQueryKeys) {
      try {
        final response = await _dio.get<dynamic>(
          ApiEndpoints.products,
          queryParameters: <String, dynamic>{
            key: trimmed,
            'limit': _searchLimit,
          },
        );
        final parsed = _parse(response.data);
        if (parsed.isNotEmpty) return parsed;
      } on DioException {
        // parametre desteklenmeyebilir; bir sonraki anahtarı dene
        continue;
      }
    }
    return const <ProductBriefModel>[];
  }

  /// GET /api/products?sku={query}
  Future<List<ProductBriefModel>> fetchByStockCode(String stockCode) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.products,
      queryParameters: <String, dynamic>{
        'sku': stockCode.trim(),
        'limit': _searchLimit,
      },
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
    final list = ApiResponseParser.parseProductList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProductBriefModel.fromJson)
        .toList();
  }
}
