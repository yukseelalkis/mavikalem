import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';

final class UpdateOrderStatus {
  const UpdateOrderStatus(this._repository);

  final OrdersRepository _repository;

  Future<void> call({
    required int orderId,
    required String? deliveryTypeRaw,
  }) {
    return _repository.updateOrderStatus(
      orderId: orderId,
      deliveryTypeRaw: deliveryTypeRaw,
    );
  }
}
