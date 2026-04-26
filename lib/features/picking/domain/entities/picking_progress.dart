import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';

enum PickedLineStatus { pending, partial, completed, excess }

class PickedLineProgress {
  const PickedLineProgress({
    required this.orderItem,
    required this.requiredQuantity,
    required this.pickedQuantity,
    required this.status,
    this.matchedItem,
  });

  final OrderItemEntity orderItem;
  final int requiredQuantity;
  final int pickedQuantity;
  final PickedLineStatus status;
  final PickedItem? matchedItem;
}

class PickingProgress {
  const PickingProgress({
    required this.orderId,
    required this.lines,
    required this.extraScans,
    required this.totalRequired,
    required this.totalPicked,
    required this.ratio,
    required this.isComplete,
  });

  final int orderId;
  final List<PickedLineProgress> lines;
  final List<PickedItem> extraScans;
  final int totalRequired;
  final int totalPicked;
  final double ratio;
  final bool isComplete;
}
