import 'package:dio/dio.dart';
import 'package:mavikalem_app/core/constants/api_endpoints.dart';
import 'package:mavikalem_app/core/network/api_response_parser.dart';
import 'package:mavikalem_app/features/orders/data/models/order_response_model.dart';
import 'package:mavikalem_app/features/orders/domain/order_sorting.dart';

final class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<OrderResponseModel>> fetchIncomingOrders({
    required int page,
    required int limit,
    String? sort,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    final response = await _dio.get<dynamic>(
      ApiEndpoints.incomingOrders,
      queryParameters: queryParameters,
    );

    final list = ApiResponseParser.parseList(response.data);
    final orders = list
        .whereType<Map<String, dynamic>>()
        .map(OrderResponseModel.fromJson)
        .toList();

    orders.sort(compareOrdersNewestFirst);

    return orders;
  }

  Future<OrderResponseModel> fetchOrderDetail(int orderId) async {
    final response = await _dio.get<dynamic>(
      '${ApiEndpoints.orderDetails}/$orderId',
    );

    final map = ApiResponseParser.parseMap(response.data);
    return OrderResponseModel.fromJson(map);
  }
}
