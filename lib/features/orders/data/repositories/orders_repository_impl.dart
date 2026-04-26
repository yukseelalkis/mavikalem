import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';

final class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._remoteDataSource);

  final OrdersRemoteDataSource _remoteDataSource;

  @override
  Future<List<OrderEntity>> getIncomingOrders({
    required int page,
    int limit = 50,
    String? customerFirstNameQuery,
  }) {
    return _remoteDataSource.fetchIncomingOrders(
      page: page,
      limit: limit,
      customerFirstNameQuery: customerFirstNameQuery,
    );
  }

  @override
  Future<OrderEntity> getOrderDetail(int orderId) {
    return _remoteDataSource.fetchOrderDetail(orderId);
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String? deliveryTypeRaw,
    OrderStatusTarget target = OrderStatusTarget.auto,
  }) {
    return _remoteDataSource.updateOrderStatus(
      orderId: orderId,
      deliveryTypeRaw: deliveryTypeRaw,
      target: target,
    );
  }
}
