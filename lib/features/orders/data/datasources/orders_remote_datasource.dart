import 'package:dio/dio.dart';
import 'package:mavikalem_app/core/constants/api_endpoints.dart';
import 'package:mavikalem_app/core/delivery/delivery_type_kind.dart';
import 'package:mavikalem_app/core/network/api_response_parser.dart';
import 'package:mavikalem_app/features/orders/data/models/order_response_model.dart';
import 'package:mavikalem_app/features/orders/domain/order_sorting.dart';

final class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  /// Postman ile uyumlu sorgu: `sort=-id`, `limit=50`, `createdAt~lte=<simdi>`,
  /// `page=<sayfa>`. Tarih cihaz yerel saati; Dio query map ile degerleri URL-encode eder.
  static const String _sortNewestIdFirst = '-id';

  /// [orders_providers] icindeki [ordersPageLimit] ile ayni kalmali.
  static const int _limit = 50;

  Future<List<OrderResponseModel>> fetchIncomingOrders({
    required int page,
  }) async {
    final lteLocal = _formatDeviceLocalDateTime(DateTime.now());
    final queryParameters = <String, dynamic>{
      'sort': _sortNewestIdFirst,
      'limit': _limit,
      'page': page,
      'createdAt~lte': lteLocal,
    };

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

  /// `yyyy-MM-dd HH:mm:ss` — API `createdAt~lte` filtre degeri (yerel zaman).
  static String _formatDeviceLocalDateTime(DateTime local) {
    String p2(int v) => v.toString().padLeft(2, '0');
    final d = local;
    return '${d.year}-${p2(d.month)}-${p2(d.day)} '
        '${p2(d.hour)}:${p2(d.minute)}:${p2(d.second)}';
  }

  Future<OrderResponseModel> fetchOrderDetail(int orderId) async {
    final response = await _dio.get<dynamic>(
      '${ApiEndpoints.orderDetails}/$orderId',
    );

    final map = ApiResponseParser.parseMap(response.data);
    return OrderResponseModel.fromJson(map);
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String? deliveryTypeRaw,
  }) async {
    final body = buildOrderStatusUpdateBody(deliveryTypeRaw);
    await _dio.put<dynamic>(
      '${ApiEndpoints.orderDetails}/$orderId',
      data: body,
    );
  }
}

Map<String, String> buildOrderStatusUpdateBody(String? deliveryTypeRaw) {
  final kind = resolveDeliveryType(deliveryTypeRaw);
  switch (kind) {
    case DeliveryTypeKind.storePickup:
    case DeliveryTypeKind.cargo:
      // Toplama tamamlandığında her iki teslimat tipinde de sipariş
      // "Hazırlanıyor" (being_prepared) statüsüne alınır.
      return const <String, String>{'status': 'being_prepared'};
    case DeliveryTypeKind.unknown:
      throw StateError(
        'Teslimat tipi anlasilamadi. Durum guncellemesi gonderilemedi.',
      );
  }
}
