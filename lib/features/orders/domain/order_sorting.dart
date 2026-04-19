import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';

/// IdeaSoft listelerinde yeniden eskiye tutarli siralama.
///
/// Oncelik: createdAt (varsa), yoksa id (genelde artan zaman sirasi).
/// Ayrica createdAt esit veya ikisi de yoksa id ile kirilir.
int compareOrdersNewestFirst(OrderEntity a, OrderEntity b) {
  final aDate = a.createdAt;
  final bDate = b.createdAt;

  if (aDate != null && bDate != null) {
    final byDate = bDate.compareTo(aDate);
    if (byDate != 0) return byDate;
  } else if (bDate != null) {
    return 1;
  } else if (aDate != null) {
    return -1;
  }

  return b.id.compareTo(a.id);
}
