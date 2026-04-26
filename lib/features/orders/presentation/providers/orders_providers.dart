import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/core/di/providers.dart';
import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:mavikalem_app/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:mavikalem_app/features/orders/domain/usecases/get_incoming_orders.dart';
import 'package:mavikalem_app/features/orders/domain/usecases/update_order_status.dart';

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return OrdersRemoteDataSource(dio);
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final remote = ref.watch(ordersRemoteDataSourceProvider);
  return OrdersRepositoryImpl(remote);
});

final getIncomingOrdersUseCaseProvider = Provider<GetIncomingOrders>((ref) {
  final repository = ref.watch(ordersRepositoryProvider);
  return GetIncomingOrders(repository);
});

final updateOrderStatusUseCaseProvider = Provider<UpdateOrderStatus>((ref) {
  final repository = ref.watch(ordersRepositoryProvider);
  return UpdateOrderStatus(repository);
});

final orderPrepareProvider = FutureProvider.family<OrderEntity, int>((
  ref,
  orderId,
) async {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.getOrderDetail(orderId);
});

final submitOrderStatusProvider =
    StateNotifierProvider.family<
      SubmitOrderStatusController,
      AsyncValue<void>,
      int
    >((ref, orderId) {
      return SubmitOrderStatusController(ref, orderId);
    });

final class SubmitOrderStatusController
    extends StateNotifier<AsyncValue<void>> {
  SubmitOrderStatusController(this._ref, this.orderId)
    : super(const AsyncData(null));

  final Ref _ref;
  final int orderId;

  /// Toplama tamamlandığında çalışır; teslimat tipine göre otomatik status
  /// (mağaza -> `delivered`, kargo -> `being_prepared`) gönderilir.
  Future<void> submit({required String? deliveryTypeRaw}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = _ref.read(updateOrderStatusUseCaseProvider);
      await useCase(orderId: orderId, deliveryTypeRaw: deliveryTypeRaw);
      _ref.invalidate(orderPrepareProvider(orderId));
      return;
    });
  }
}

final markOrderDeliveredProvider =
    StateNotifierProvider.family<
      MarkOrderDeliveredController,
      AsyncValue<void>,
      int
    >((ref, orderId) {
      return MarkOrderDeliveredController(ref, orderId);
    });

/// "Teslim Et" aksiyonu için ayrı bir kontroller; teslimat tipinden bağımsız
/// olarak siparişi doğrudan `delivered` statüsüne taşıyan final isteği atar.
/// Loading / error state'i `submitOrderStatusProvider`'dan ayrık tutularak UI
/// her iki aksiyonun ilerleyişini bağımsız gösterebilir.
final class MarkOrderDeliveredController
    extends StateNotifier<AsyncValue<void>> {
  MarkOrderDeliveredController(this._ref, this.orderId)
    : super(const AsyncData(null));

  final Ref _ref;
  final int orderId;

  Future<void> markAsDelivered() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = _ref.read(updateOrderStatusUseCaseProvider);
      await useCase(
        orderId: orderId,
        deliveryTypeRaw: null,
        target: OrderStatusTarget.delivered,
      );
      _ref.invalidate(orderPrepareProvider(orderId));
      return;
    });
  }
}
