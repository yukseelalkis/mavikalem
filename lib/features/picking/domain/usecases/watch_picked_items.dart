import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';
import 'package:mavikalem_app/features/picking/domain/repositories/picking_repository.dart';

final class WatchPickedItems {
  const WatchPickedItems(this._repository);

  final PickingRepository _repository;

  Stream<List<PickedItem>> call(int orderId) {
    return _repository.watchPickedItems(orderId);
  }
}
