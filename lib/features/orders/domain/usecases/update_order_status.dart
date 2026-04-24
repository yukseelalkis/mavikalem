import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';

final class UpdateOrderStatus {
  const UpdateOrderStatus(this._repository);

  final OrdersRepository _repository;

  Future<void> call({
    required int orderId,
    required String? deliveryTypeRaw,
    OrderStatusTarget target = OrderStatusTarget.auto,
  }) {
    return _repository.updateOrderStatus(
      orderId: orderId,
      deliveryTypeRaw: deliveryTypeRaw,
      target: target,
    );
  }
}
