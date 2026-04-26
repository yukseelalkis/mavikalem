import 'package:mavikalem_app/features/picking/data/models/picked_item_model.dart';
import 'package:mavikalem_app/features/picking/data/datasources/picking_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabasePickingRemoteDataSource implements PickingRemoteDataSource {
  const SupabasePickingRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<PickedItemModel?> findPickedItem({
    required int orderId,
    required String sku,
  }) async {
    final rows =
        await _client
                .from('picked_items')
                .select()
                .eq('order_id', orderId)
                .eq('sku', sku)
                .limit(1)
            as List<dynamic>;
    if (rows.isEmpty) return null;
    final first = rows.first as Map<String, dynamic>;
    return PickedItemModel.fromMap(first);
  }

  @override
  Future<void> upsertPickedItem({
    required int orderId,
    required String sku,
    required String productName,
    required int quantity,
  }) async {
    await _client.from('picked_items').upsert(<String, dynamic>{
      'order_id': orderId,
      'sku': sku,
      'product_name': productName,
      'quantity': quantity,
    }, onConflict: 'order_id,sku');
  }

  @override
  Stream<List<PickedItemModel>> streamPickedItemsByOrder(int orderId) {
    return _client
        .from('picked_items')
        .stream(primaryKey: <String>['id'])
        .eq('order_id', orderId)
        .order('updated_at')
        .map(
          (rows) => rows.map(PickedItemModel.fromMap).toList(growable: false),
        );
  }
}
