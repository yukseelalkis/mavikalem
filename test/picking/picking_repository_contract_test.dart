import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/picking/data/datasources/picking_remote_datasource.dart';
import 'package:mavikalem_app/features/picking/data/models/picked_item_model.dart';
import 'package:mavikalem_app/features/picking/data/repositories/supabase_picking_repository_impl.dart';

final class _FakeRemoteDataSource implements PickingRemoteDataSource {
  PickedItemModel? current;
  String? lastSku;
  int? lastQuantity;

  @override
  Future<PickedItemModel?> findPickedItem({
    required int orderId,
    required String sku,
  }) async {
    if (current == null) return null;
    if (current!.orderId == orderId && current!.sku == sku) return current;
    return null;
  }

  @override
  Future<void> upsertPickedItem({
    required int orderId,
    required String sku,
    required String productName,
    required int quantity,
  }) async {
    lastSku = sku;
    lastQuantity = quantity;
    current = PickedItemModel(
      id: '1',
      orderId: orderId,
      sku: sku,
      productName: productName,
      quantity: quantity,
      updatedAt: DateTime(2026),
    );
  }

  @override
  Stream<List<PickedItemModel>> streamPickedItemsByOrder(int orderId) {
    return const Stream<List<PickedItemModel>>.empty();
  }
}

void main() {
  group('SupabasePickingRepositoryImpl', () {
    late _FakeRemoteDataSource remote;
    late SupabasePickingRepositoryImpl repository;

    setUp(() {
      remote = _FakeRemoteDataSource();
      repository = SupabasePickingRepositoryImpl(remote);
    });

    test('adds new row when sku does not exist', () async {
      await repository.addPickedItem(101, 'SKU-1', 1);

      expect(remote.lastSku, 'SKU-1');
      expect(remote.lastQuantity, 1);
    });

    test('increments quantity when sku already exists', () async {
      remote.current = PickedItemModel(
        id: '1',
        orderId: 101,
        sku: 'SKU-1',
        productName: 'SKU-1',
        quantity: 2,
        updatedAt: DateTime(2026),
      );

      await repository.addPickedItem(101, 'SKU-1', 3);

      expect(remote.lastSku, 'SKU-1');
      expect(remote.lastQuantity, 5);
    });

    test('decrements quantity when delta is negative', () async {
      remote.current = PickedItemModel(
        id: '1',
        orderId: 101,
        sku: 'SKU-1',
        productName: 'SKU-1',
        quantity: 4,
        updatedAt: DateTime(2026),
      );

      await repository.addPickedItem(101, 'SKU-1', -2);

      expect(remote.lastSku, 'SKU-1');
      expect(remote.lastQuantity, 2);
    });

    test('clamps quantity to zero on excessive negative delta', () async {
      remote.current = PickedItemModel(
        id: '1',
        orderId: 101,
        sku: 'SKU-1',
        productName: 'SKU-1',
        quantity: 1,
        updatedAt: DateTime(2026),
      );

      await repository.addPickedItem(101, 'SKU-1', -9);

      expect(remote.lastQuantity, 0);
    });

    test('throws when sku is empty', () async {
      expect(
        () => repository.addPickedItem(101, '   ', 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when delta is zero', () async {
      expect(
        () => repository.addPickedItem(101, 'SKU-1', 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
