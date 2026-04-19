import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';

abstract interface class OrdersRepository {
  Future<List<OrderEntity>> getIncomingOrders({
    required int page,
    required int limit,
    String? sort,
  });
  Future<OrderEntity> getOrderDetail(int orderId);
}
