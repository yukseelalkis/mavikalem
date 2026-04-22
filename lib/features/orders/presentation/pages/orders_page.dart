import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mavikalem_app/core/widgets/delivery_type_badge.dart';
import 'package:mavikalem_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_bucket.dart';
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
    final statusBucket = OrderStatusBucket.bucketForRawStatus(order.status);

    return ListTile(
      title: Text('#${order.id} - ${order.customerName}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${order.items.length} urun • $createdAtText',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          DeliveryTypeBadge(
            rawValue: order.deliveryTypeRaw,
            unknownLabel: 'Teslimat Bilgisi Yok',
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderStatusChip(bucket: statusBucket),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: 'API durumu: ${order.status}',
                  child: Text(
                    order.status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
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

final class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.bucket});

  final OrderStatusBucket bucket;

  Color _background(ColorScheme scheme) => switch (bucket) {
    OrderStatusBucket.all => scheme.surfaceContainerHighest,
    OrderStatusBucket.yeni => scheme.primaryContainer,
    OrderStatusBucket.hazirlaniyor => scheme.tertiaryContainer,
    OrderStatusBucket.tamamlandi => scheme.secondaryContainer,
    OrderStatusBucket.diger => scheme.surfaceContainerHighest,
  };

  Color _foreground(ColorScheme scheme) => switch (bucket) {
    OrderStatusBucket.all => scheme.onSurfaceVariant,
    OrderStatusBucket.yeni => scheme.onPrimaryContainer,
    OrderStatusBucket.hazirlaniyor => scheme.onTertiaryContainer,
    OrderStatusBucket.tamamlandi => scheme.onSecondaryContainer,
    OrderStatusBucket.diger => scheme.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(
        bucket.label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: _foreground(scheme),
        ),
      ),
      backgroundColor: _background(scheme),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
