part of 'orders_bloc.dart';

enum OrdersStatus { initial, loading, success, loadingMore, failure }

final class OrdersState extends Equatable {
  const OrdersState({
    required this.status,
    required this.orders,
    required this.currentPage,
    required this.hasMore,
    this.searchQuery,
    this.errorMessage,
  });

  const OrdersState.initial()
    : status = OrdersStatus.initial,
      orders = const <OrderEntity>[],
      currentPage = 0,
      hasMore = true,
      searchQuery = null,
      errorMessage = null;

  final OrdersStatus status;
  final List<OrderEntity> orders;
  final int currentPage;
  final bool hasMore;
  final String? searchQuery;
  final String? errorMessage;

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderEntity>? orders,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    orders,
    currentPage,
    hasMore,
    searchQuery,
    errorMessage,
  ];
}
