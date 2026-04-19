import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/shipping_address_entity.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/presentation/providers/product_check_providers.dart';

final class OrderPreparePage extends ConsumerWidget {
  const OrderPreparePage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderPrepareProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Siparis detay #$orderId')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Siparis detayi yuklenemedi: $error'),
          ),
        ),
        data: (order) => RefreshIndicator(
          onRefresh: () => ref.refresh(orderPrepareProvider(orderId).future),
          child: _OrderDetailScrollView(order: order),
        ),
      ),
    );
  }
}

final class _OrderDetailScrollView extends StatelessWidget {
  const _OrderDetailScrollView({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _OrderSummaryCard(order: order)),
        if (order.items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Bu sipariste urun kalemi yok.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderLineCard(item: item),
                  );
                },
                childCount: order.items.length,
              ),
            ),
          ),
        if (order.shippingAddress != null &&
            !order.shippingAddress!.isEmpty)
          SliverToBoxAdapter(
            child: _ShippingCard(address: order.shippingAddress!),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

final class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = order.finalAmount != null
        ? '${order.finalAmount!.toStringAsFixed(2)} TL'
        : '-';
    final payment = order.paymentTypeName ?? '-';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Siparis ozeti', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Toplam',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  amountText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Odeme tipi',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(payment, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

final class _OrderLineCard extends ConsumerWidget {
  const _OrderLineCard({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qtyText = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductThumb(productId: item.productId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LabeledRow(
                    label: 'Barkod',
                    value: item.barcode,
                    monospace: true,
                    onCopy: () => _copy(context, 'Barkod', item.barcode),
                  ),
                  const SizedBox(height: 6),
                  _LabeledRow(
                    label: 'Stok kodu',
                    value: item.stockCode,
                    monospace: true,
                    onCopy: () => _copy(context, 'Stok kodu', item.stockCode),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Adet',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          qtyText,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProductThumb extends ConsumerWidget {
  const _ProductThumb({required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const size = 96.0;

    if (productId <= 0) {
      return _thumbFrame(
        size,
        Icon(Icons.inventory_2_outlined, color: theme.colorScheme.outline),
      );
    }

    final async = ref.watch(productBriefByIdProvider(productId));

    return async.when(
      loading: () => _thumbFrame(
        size,
        const Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => _thumbFrame(
        size,
        Icon(Icons.broken_image_outlined, color: theme.colorScheme.error),
      ),
      data: (ProductBriefEntity product) {
        final url = product.imageUrl.trim();
        if (url.isEmpty) {
          return _thumbFrame(
            size,
            Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.outline,
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth:
                (size * MediaQuery.of(context).devicePixelRatio).round(),
            placeholder: (_, __) => Container(
              width: size,
              height: size,
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => _thumbFrame(
              size,
              Icon(Icons.broken_image_outlined, color: theme.colorScheme.error),
            ),
          ),
        );
      },
    );
  }

  Widget _thumbFrame(double size, Widget child) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

final class _LabeledRow extends StatelessWidget {
  const _LabeledRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.monospace = false,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        monospace
            ? theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 0.4,
            )
            : theme.textTheme.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SelectableText(
                value,
                style: textStyle?.copyWith(fontSize: 17),
              ),
            ),
            IconButton(
              tooltip: 'Kopyala',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 22),
            ),
          ],
        ),
      ],
    );
  }
}

final class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.address});

  final ShippingAddressEntity address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teslimat bilgileri',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Ad Soyad',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              address.fullName.isEmpty ? '-' : address.fullName,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Telefon',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    address.phone.isEmpty ? '-' : address.phone,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Telefonu kopyala',
                  onPressed:
                      address.phone.isEmpty
                          ? null
                          : () => _copy(context, 'Telefon', address.phone),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Adres',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            if (address.address.isNotEmpty)
              SelectableText(
                address.address,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
            if (address.address.isEmpty)
              Text('-', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            if (address.location.isNotEmpty ||
                address.subLocation.isNotEmpty)
              SelectableText(
                [
                  address.location,
                  address.subLocation,
                ].where((s) => s.trim().isNotEmpty).join(', '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _copy(BuildContext context, String label, String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty || trimmed == '-') return;
  await Clipboard.setData(ClipboardData(text: trimmed));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label kopyalandi')),
  );
}
