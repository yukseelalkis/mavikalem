import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picking_progress.dart';
import 'package:mavikalem_app/features/picking/domain/repositories/picking_repository.dart';
import 'package:mavikalem_app/features/picking/domain/services/order_picking_matcher.dart';
import 'package:rxdart/rxdart.dart';

final class WatchOrderPickingProgress {
  const WatchOrderPickingProgress(this._repository);

  final PickingRepository _repository;

  Stream<PickingProgress> call({
    required int orderId,
    required Stream<List<OrderItemEntity>> orderItemsStream,
  }) {
    final pickedItemsStream = _repository.watchPickedItems(orderId);

    return Rx.combineLatest2<
      List<OrderItemEntity>,
      List<PickedItem>,
      PickingProgress
    >(
      orderItemsStream,
      pickedItemsStream,
      (orderItems, pickedItems) => OrderPickingMatcher.combine(
        orderId: orderId,
        orderItems: orderItems,
        pickedItems: pickedItems,
      ),
    );
  }
}
