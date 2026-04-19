import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';

final class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._remoteDataSource);

  final OrdersRemoteDataSource _remoteDataSource;

  @override
  Future<List<OrderEntity>> getIncomingOrders({
    required int page,
  }) {
    return _remoteDataSource.fetchIncomingOrders(page: page);
  }

  @override
  Future<OrderEntity> getOrderDetail(int orderId) {
    return _remoteDataSource.fetchOrderDetail(orderId);
  }
}
