import 'package:mavikalem_app/features/picking/data/datasources/picking_remote_datasource.dart';
import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';
import 'package:mavikalem_app/features/picking/domain/repositories/picking_repository.dart';

final class SupabasePickingRepositoryImpl implements PickingRepository {
  SupabasePickingRepositoryImpl(this._remoteDataSource);

  final PickingRemoteDataSource _remoteDataSource;

  @override
  Future<void> addPickedItem(int orderId, String sku, int quantityDelta) async {
    final normalizedSku = sku.trim();
    if (normalizedSku.isEmpty) {
      throw ArgumentError.value(sku, 'sku', 'SKU cannot be empty');
    }
    if (quantityDelta == 0) {
      throw ArgumentError.value(
        quantityDelta,
        'quantityDelta',
        'Quantity delta cannot be 0',
      );
    }

    final existing = await _remoteDataSource.findPickedItem(
      orderId: orderId,
      sku: normalizedSku,
    );
    final newQuantity = ((existing?.quantity ?? 0) + quantityDelta)
        .clamp(0, 1 << 31)
        .toInt();
    await _remoteDataSource.upsertPickedItem(
      orderId: orderId,
      sku: normalizedSku,
      productName: normalizedSku,
      quantity: newQuantity,
    );
  }

  @override
  Stream<List<PickedItem>> watchPickedItems(int orderId) {
    return _remoteDataSource.streamPickedItemsByOrder(orderId);
  }
}
