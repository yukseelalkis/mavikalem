import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/core/di/providers.dart';
import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:mavikalem_app/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_sorting.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:mavikalem_app/features/orders/domain/usecases/get_incoming_orders.dart';

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

const int ordersPageLimit = 50;

class OrdersPaginationState {
  const OrdersPaginationState({
    required this.orders,
    required this.currentPage,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.errorMessage,
  });

  const OrdersPaginationState.initial()
    : orders = const <OrderEntity>[],
      currentPage = 0,
      isInitialLoading = false,
      isLoadingMore = false,
      hasMore = true,
      errorMessage = null;

  final List<OrderEntity> orders;
  final int currentPage;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  OrdersPaginationState copyWith({
    List<OrderEntity>? orders,
    int? currentPage,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersPaginationState(
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final ordersPaginationProvider =
    StateNotifierProvider<OrdersPaginationController, OrdersPaginationState>((
      ref,
    ) {
      final controller = OrdersPaginationController(ref);
      controller.loadInitial();
      return controller;
    });

final class OrdersPaginationController
    extends StateNotifier<OrdersPaginationState> {
  OrdersPaginationController(this._ref)
    : super(const OrdersPaginationState.initial());

  final Ref _ref;

  Future<void> loadInitial() async {
    if (state.isInitialLoading) return;
    state = state.copyWith(
      isInitialLoading: true,
      clearError: true,
      hasMore: true,
      currentPage: 0,
      orders: const <OrderEntity>[],
    );

    try {
      final useCase = _ref.read(getIncomingOrdersUseCaseProvider);
      final firstPage = await useCase(page: 1);

      state = state.copyWith(
        isInitialLoading: false,
        currentPage: 1,
        hasMore: firstPage.length >= ordersPageLimit,
        orders: _sortOrders(firstPage),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;
      final useCase = _ref.read(getIncomingOrdersUseCaseProvider);
      final incoming = await useCase(page: nextPage);

      final merged = _dedupeById(<OrderEntity>[...state.orders, ...incoming]);

      state = state.copyWith(
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: incoming.length >= ordersPageLimit,
        orders: _sortOrders(merged),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  List<OrderEntity> _sortOrders(List<OrderEntity> input) {
    final output = List<OrderEntity>.from(input);
    output.sort(compareOrdersNewestFirst);
    return output;
  }

  List<OrderEntity> _dedupeById(List<OrderEntity> input) {
    final map = <int, OrderEntity>{};
    for (final order in input) {
      map[order.id] = order;
    }
    return map.values.toList();
  }
}

final orderPrepareProvider = FutureProvider.family<OrderEntity, int>((
  ref,
  orderId,
) async {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.getOrderDetail(orderId);
});
