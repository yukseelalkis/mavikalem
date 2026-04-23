import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mavikalem_app/core/widgets/delivery_type_badge.dart';
import 'package:mavikalem_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_bucket.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_localization.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/order_prepare_page.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';

final class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

final class _OrdersPageState extends ConsumerState<OrdersPage> {
  late final ScrollController _scrollController;
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Expanded(child: _buildBody(state)),
        ],
      ),
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

    final visible = _filtered(state.orders);
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Bu filtrede siparis yok (${_statusFilter.label}).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: visible.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, index) {
        if (index == visible.length - 1 && state.isLoadingMore) {
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

    final theme = Theme.of(context);
    final statusStyle = OrderStatusLocalization.styleForRaw(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderPreparePage(orderId: order.id),
            ),
          );
        },
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
