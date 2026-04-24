import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';

abstract interface class OrdersRepository {
  Future<List<OrderEntity>> getIncomingOrders({
    required int page,
  });
  Future<OrderEntity> getOrderDetail(int orderId);
  Future<void> updateOrderStatus({
    required int orderId,
    required String? deliveryTypeRaw,
    OrderStatusTarget target = OrderStatusTarget.auto,
  });
}
