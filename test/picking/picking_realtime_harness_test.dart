import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/picking/data/datasources/picking_remote_datasource.dart';
import 'package:mavikalem_app/features/picking/data/models/picked_item_model.dart';
import 'package:mavikalem_app/features/picking/data/repositories/supabase_picking_repository_impl.dart';

final class _InMemoryPickingRemoteDataSource
    implements PickingRemoteDataSource {
  final Map<String, PickedItemModel> _pickedByComposite =
      <String, PickedItemModel>{};
  final Map<int, StreamController<List<PickedItemModel>>> _orderControllers =
      <int, StreamController<List<PickedItemModel>>>{};

  int _pickedCounter = 0;

  @override
  Future<PickedItemModel?> findPickedItem({
    required int orderId,
    required String sku,
  }) async {
    return _pickedByComposite['$orderId::$sku'];
  }

  @override
  Future<void> upsertPickedItem({
    required int orderId,
    required String sku,
    required String productName,
    required int quantity,
  }) async {
    final key = '$orderId::$sku';
    final now = DateTime.now();
    final existing = _pickedByComposite[key];
    _pickedByComposite[key] = existing == null
        ? PickedItemModel(
            id: 'p${++_pickedCounter}',
            orderId: orderId,
            sku: sku,
            productName: productName,
            quantity: quantity,
            updatedAt: now,
          )
        : PickedItemModel(
            id: existing.id,
            orderId: existing.orderId,
            sku: existing.sku,
            productName: productName,
            quantity: quantity,
            updatedAt: now,
          );
    _emitOrder(orderId);
  }

  @override
  Stream<List<PickedItemModel>> streamPickedItemsByOrder(int orderId) {
    final controller = _orderControllers.putIfAbsent(
      orderId,
      () => StreamController<List<PickedItemModel>>.broadcast(),
    );
    scheduleMicrotask(() => _emitOrder(orderId));
    return controller.stream;
  }

  void _emitOrder(int orderId) {
    final controller = _orderControllers[orderId];
    if (controller == null || controller.isClosed) return;
    final rows = _pickedByComposite.values
        .where((item) => item.orderId == orderId)
        .toList(growable: false);
    controller.add(rows);
  }
}

void main() {
  test('two devices see single row with accumulated quantity', () async {
    final remote = _InMemoryPickingRemoteDataSource();
    final repoA = SupabasePickingRepositoryImpl(remote);
    final repoB = SupabasePickingRepositoryImpl(remote);

    final streamA = repoA.watchPickedItems(77);
    final streamB = repoB.watchPickedItems(77);

    final futureA = streamA.firstWhere(
      (rows) => rows.length == 1 && rows.single.quantity == 2,
    );
    final futureB = streamB.firstWhere(
      (rows) => rows.length == 1 && rows.single.quantity == 2,
    );

    await repoA.addPickedItem(77, 'SKU-A', 1);
    await repoB.addPickedItem(77, 'SKU-A', 1);

    final latestA = await futureA;
    final latestB = await futureB;

    expect(latestA.length, 1);
    expect(latestB.length, 1);
    expect(latestA.single.sku, 'SKU-A');
    expect(latestB.single.sku, 'SKU-A');
    expect(latestA.single.quantity, 2);
    expect(latestB.single.quantity, 2);
  });
}
