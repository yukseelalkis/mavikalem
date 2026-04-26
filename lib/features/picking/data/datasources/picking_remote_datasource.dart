import 'package:mavikalem_app/features/picking/data/models/picked_item_model.dart';

abstract interface class PickingRemoteDataSource {
  Future<PickedItemModel?> findPickedItem({
    required int orderId,
    required String sku,
  });

  Future<void> upsertPickedItem({
    required int orderId,
    required String sku,
    required String productName,
    required int quantity,
  });

  Stream<List<PickedItemModel>> streamPickedItemsByOrder(int orderId);
}
