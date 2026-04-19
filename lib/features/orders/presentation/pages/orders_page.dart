import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mavikalem_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/order_prepare_page.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';

final class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

final class _OrdersPageState extends ConsumerState<OrdersPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(ordersPaginationProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersPaginationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelen Siparisler'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () =>
                ref.read(ordersPaginationProvider.notifier).loadInitial(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cikis',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(OrdersPaginationState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Siparisler getirilemedi: ${state.errorMessage}'),
        ),
      );
    }

    if (state.orders.isEmpty) {
      return const Center(child: Text('Gelen siparis bulunamadi.'));
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, index) {
        if (index == state.orders.length - 1 && state.isLoadingMore) {
          return const SizedBox.shrink();
        }
        return const Divider(height: 0);
      },
      itemBuilder: (context, index) {
        if (index >= state.orders.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.orders[index];
        return _OrderTile(order: order);
      },
    );
  }
}

final class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final createdAtText = order.createdAt == null
        ? '-'
        : DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt!.toLocal());

    return ListTile(
      title: Text('#${order.id} - ${order.customerName}'),
      subtitle: Text('${order.items.length} urun • $createdAtText'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderPreparePage(orderId: order.id),
          ),
        );
      },
    );
  }
}
