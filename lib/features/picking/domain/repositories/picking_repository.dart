import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';

abstract interface class PickingRepository {
  Future<void> addPickedItem(int orderId, String sku, int quantityDelta);
  Stream<List<PickedItem>> watchPickedItems(int orderId);
}
