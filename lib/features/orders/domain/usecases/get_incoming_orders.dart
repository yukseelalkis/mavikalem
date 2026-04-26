import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';

final class GetIncomingOrders {
  const GetIncomingOrders(this._repository);

  final OrdersRepository _repository;

  Future<List<OrderEntity>> call({
    required int page,
    int limit = 50,
    String? customerFirstNameQuery,
  }) {
    return _repository.getIncomingOrders(
      page: page,
      limit: limit,
      customerFirstNameQuery: customerFirstNameQuery,
    );
  }
}
