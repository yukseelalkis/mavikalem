import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';

final class _FakeOrdersRepository implements OrdersRepository {
  _FakeOrdersRepository({this.shouldThrow = false});

  final bool shouldThrow;
  int? lastOrderId;
  String? lastDeliveryTypeRaw;
  OrderStatusTarget? lastTarget;

  @override
  Future<List<OrderEntity>> getIncomingOrders({required int page}) async {
    return const <OrderEntity>[];
  }

  @override
  Future<OrderEntity> getOrderDetail(int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String? deliveryTypeRaw,
    OrderStatusTarget target = OrderStatusTarget.auto,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (shouldThrow) throw StateError('failed');
    lastOrderId = orderId;
    lastDeliveryTypeRaw = deliveryTypeRaw;
    lastTarget = target;
  }
}

void main() {
  test('submitOrderStatusProvider goes loading then data on success', () async {
    final fakeRepo = _FakeOrdersRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        ordersRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(submitOrderStatusProvider(99).notifier);
    final future = notifier.submit(deliveryTypeRaw: 'kargo');

    expect(container.read(submitOrderStatusProvider(99)).isLoading, isTrue);

    await future;
    final state = container.read(submitOrderStatusProvider(99));
    expect(state.hasError, isFalse);
    expect(fakeRepo.lastOrderId, 99);
    expect(fakeRepo.lastDeliveryTypeRaw, 'kargo');
    expect(fakeRepo.lastTarget, OrderStatusTarget.auto);
  });

  test('submitOrderStatusProvider exposes error on failure', () async {
    final fakeRepo = _FakeOrdersRepository(shouldThrow: true);
    final container = ProviderContainer(
      overrides: <Override>[
        ordersRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(submitOrderStatusProvider(42).notifier)
        .submit(deliveryTypeRaw: 'unknown');

    final state = container.read(submitOrderStatusProvider(42));
    expect(state.hasError, isTrue);
  });

  test('markOrderDeliveredProvider sends delivered target and updates state',
      () async {
    final fakeRepo = _FakeOrdersRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        ordersRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      markOrderDeliveredProvider(77).notifier,
    );
    final future = notifier.markAsDelivered();

    expect(
      container.read(markOrderDeliveredProvider(77)).isLoading,
      isTrue,
    );

    await future;

    final state = container.read(markOrderDeliveredProvider(77));
    expect(state.hasError, isFalse);
    expect(fakeRepo.lastOrderId, 77);
    expect(fakeRepo.lastDeliveryTypeRaw, isNull);
    expect(fakeRepo.lastTarget, OrderStatusTarget.delivered);
  });

  test('markOrderDeliveredProvider exposes error on failure', () async {
    final fakeRepo = _FakeOrdersRepository(shouldThrow: true);
    final container = ProviderContainer(
      overrides: <Override>[
        ordersRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(markOrderDeliveredProvider(55).notifier)
        .markAsDelivered();

    final state = container.read(markOrderDeliveredProvider(55));
    expect(state.hasError, isTrue);
  });
}
