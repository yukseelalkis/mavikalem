import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mavikalem_app/core/widgets/delivery_type_badge.dart';
import 'package:mavikalem_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_bucket.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_localization.dart';
import 'package:mavikalem_app/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/order_prepare_page.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';

final class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(ordersRepositoryProvider);
    return BlocProvider<OrdersBloc>(
      create: (_) => OrdersBloc(repository)..add(const OrdersStarted()),
      child: const _OrdersView(),
    );
  }
}

final class _OrdersView extends ConsumerStatefulWidget {
  const _OrdersView();

  @override
  ConsumerState<_OrdersView> createState() => _OrdersViewState();
}

final class _OrdersViewState extends ConsumerState<_OrdersView> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  OrderStatusBucket _statusFilter = OrderStatusBucket.all;

  List<OrderEntity> _filtered(List<OrderEntity> orders) {
    if (_statusFilter == OrderStatusBucket.all) return orders;
    return orders.where((o) {
      final b = OrderStatusBucket.bucketForRawStatus(o.status);
      return _statusFilter.matches(b);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      context.read<OrdersBloc>().add(const OrdersLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrdersBloc>().state;
    final isLoading = state.status == OrdersStatus.loading;
    final isLoadingMore = state.status == OrdersStatus.loadingMore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelen Siparisler'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () =>
                context.read<OrdersBloc>().add(const OrdersRefreshed()),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cikis',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Musteri adina gore ara',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Temizle',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      context.read<OrdersBloc>().add(
                        const OrdersSearchCleared(),
                      );
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: (text) {
                setState(() {});
                context.read<OrdersBloc>().add(OrdersSearchQueryChanged(text));
              },
            ),
          ),
          if (isLoading || isLoadingMore) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final bucket in [
                    OrderStatusBucket.all,
                    OrderStatusBucket.yeni,
                    OrderStatusBucket.hazirlaniyor,
                    OrderStatusBucket.tamamlandi,
                    OrderStatusBucket.diger,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: FilterChip(
                        label: Text(bucket.label),
                        selected: _statusFilter == bucket,
                        onSelected: (selected) {
                          setState(() {
                            _statusFilter = selected
                                ? bucket
                                : OrderStatusBucket.all;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody(state, isLoadingMore)),
        ],
      ),
    );
  }

  Widget _buildBody(OrdersState state, bool isLoadingMore) {
    if (state.status == OrdersStatus.initial ||
        state.status == OrdersStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == OrdersStatus.failure && state.orders.isEmpty) {
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

    final visible = _filtered(state.orders);
    if (visible.isEmpty) {
      final query = state.searchQuery;
      final hasQuery = query != null && query.isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            hasQuery
                ? '\'$query\' icin sonuc bulunamadi.'
                : 'Bu filtrede siparis yok (${_statusFilter.label}).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: visible.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, index) {
        if (index == visible.length - 1 && isLoadingMore) {
          return const SizedBox.shrink();
        }
        return const Divider(height: 0);
      },
      itemBuilder: (context, index) {
        if (index >= visible.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final order = visible[index];
        return _OrderTile(
          order: order,
          onTap: () async {
            final updated = await Navigator.of(context).push<OrderEntity>(
              MaterialPageRoute<OrderEntity>(
                builder: (_) => OrderPreparePage(orderId: order.id),
              ),
            );
            if (!context.mounted || updated == null) return;
            context.read<OrdersBloc>().add(OrdersOrderPatched(updated));
          },
        );
      },
    );
  }
}

final class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final OrderEntity order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAtText = order.createdAt == null
        ? '-'
        : DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt!.toLocal());

    final theme = Theme.of(context);
    final statusStyle = OrderStatusLocalization.styleForRaw(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '#${order.id} - ${order.customerName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.items.length} urun • $createdAtText',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DeliveryTypeBadge(
                      rawValue: order.deliveryTypeRaw,
                      unknownLabel: 'Teslimat Bilgisi Yok',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProminentOrderStatusBadge(style: statusStyle),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProminentOrderStatusBadge extends StatelessWidget {
  const _ProminentOrderStatusBadge({required this.style});

  final OrderStatusDisplayStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_circle_rounded, color: style.color, size: 20),
          const SizedBox(width: 8),
          Text(
            style.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: style.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
