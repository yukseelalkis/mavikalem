part of 'orders_bloc.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class OrdersStarted extends OrdersEvent {
  const OrdersStarted();
}

final class OrdersRefreshed extends OrdersEvent {
  const OrdersRefreshed();
}

final class OrdersLoadMoreRequested extends OrdersEvent {
  const OrdersLoadMoreRequested();
}

final class OrdersSearchQueryChanged extends OrdersEvent {
  const OrdersSearchQueryChanged(this.rawText);

  final String rawText;

  @override
  List<Object?> get props => <Object?>[rawText];
}

final class OrdersSearchCleared extends OrdersEvent {
  const OrdersSearchCleared();
}

final class OrdersOrderPatched extends OrdersEvent {
  const OrdersOrderPatched(this.updatedOrder);

  final OrderEntity updatedOrder;

  @override
  List<Object?> get props => <Object?>[updatedOrder];
}
