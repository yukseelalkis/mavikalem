import 'package:mavikalem_app/features/picking/domain/repositories/picking_repository.dart';

final class AddPickedItem {
  const AddPickedItem(this._repository);

  final PickingRepository _repository;

  Future<void> call({
    required int orderId,
    required String sku,
    required int quantityDelta,
  }) {
    return _repository.addPickedItem(orderId, sku, quantityDelta);
  }
}
