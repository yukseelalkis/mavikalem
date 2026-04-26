import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_sorting.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'orders_event.dart';
part 'orders_state.dart';

EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (events, mapper) =>
      restartable<E>().call(events.debounceTime(duration), mapper);
}

final class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repository) : super(const OrdersState.initial()) {
    on<OrdersStarted>(_onStarted);
    on<OrdersRefreshed>(_onRefreshed);
    on<OrdersLoadMoreRequested>(_onLoadMore, transformer: droppable());
    on<OrdersSearchQueryChanged>(
      _onSearchChanged,
      transformer: _debounceRestartable<OrdersSearchQueryChanged>(
        const Duration(milliseconds: 500),
      ),
    );
    on<OrdersSearchCleared>(_onSearchCleared);
    on<OrdersOrderPatched>(_onOrderPatched);
  }

  static const int _pageLimit = 50;

  final OrdersRepository _repository;

  Future<void> _onStarted(
    OrdersStarted event,
    Emitter<OrdersState> emit,
  ) async {
    await _fetchFirstPage(emit, searchQuery: state.searchQuery);
  }

  Future<void> _onRefreshed(
    OrdersRefreshed event,
    Emitter<OrdersState> emit,
  ) async {
    await _fetchFirstPage(emit, searchQuery: state.searchQuery);
  }

  Future<void> _onLoadMore(
    OrdersLoadMoreRequested event,
    Emitter<OrdersState> emit,
  ) async {
    if (state.status != OrdersStatus.success || !state.hasMore) return;

    emit(state.copyWith(status: OrdersStatus.loadingMore, clearError: true));

    try {
      final nextPage = state.currentPage + 1;
      final incoming = await _repository.getIncomingOrders(
        page: nextPage,
        limit: _pageLimit,
        customerFirstNameQuery: state.searchQuery,
      );
      final merged = _dedupeById(<OrderEntity>[...state.orders, ...incoming]);

      emit(
        state.copyWith(
          status: OrdersStatus.success,
          currentPage: nextPage,
          hasMore: incoming.length >= _pageLimit,
          orders: _sortOrders(merged),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: state.orders.isEmpty
              ? OrdersStatus.failure
              : OrdersStatus.success,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSearchChanged(
    OrdersSearchQueryChanged event,
    Emitter<OrdersState> emit,
  ) async {
    final trimmed = event.rawText.trim();
    if (trimmed.isEmpty) {
      await _fetchFirstPage(emit, searchQuery: null);
      return;
    }

    await _fetchFirstPage(emit, searchQuery: trimmed);
  }

  Future<void> _onSearchCleared(
    OrdersSearchCleared event,
    Emitter<OrdersState> emit,
  ) async {
    await _fetchFirstPage(emit, searchQuery: null);
  }

  void _onOrderPatched(OrdersOrderPatched event, Emitter<OrdersState> emit) {
    var found = false;
    final updatedList = state.orders
        .map((order) {
          if (order.id != event.updatedOrder.id) return order;
          found = true;
          return event.updatedOrder;
        })
        .toList(growable: false);

    if (!found) return;

    emit(state.copyWith(orders: _sortOrders(updatedList)));
  }

  Future<void> _fetchFirstPage(
    Emitter<OrdersState> emit, {
    required String? searchQuery,
  }) async {
    emit(
      state.copyWith(
        status: OrdersStatus.loading,
        orders: const <OrderEntity>[],
        currentPage: 0,
        hasMore: true,
        searchQuery: searchQuery,
        clearError: true,
      ),
    );

    try {
      final firstPage = await _repository.getIncomingOrders(
        page: 1,
        limit: _pageLimit,
        customerFirstNameQuery: searchQuery,
      );
      emit(
        state.copyWith(
          status: OrdersStatus.success,
          currentPage: 1,
          hasMore: firstPage.length >= _pageLimit,
          orders: _sortOrders(firstPage),
          searchQuery: searchQuery,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OrdersStatus.failure,
          errorMessage: error.toString(),
        ),
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
