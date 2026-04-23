import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/shipping_address_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_pack_matcher.dart';
import 'package:mavikalem_app/features/orders/domain/order_submit_validation.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/pack_progress_providers.dart';
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
          child: _OrderPrepareBody(order: order),
        ),
      ),
    );
  }
}

final class _OrderPrepareBody extends ConsumerStatefulWidget {
  const _OrderPrepareBody({required this.order});

  final OrderEntity order;

  @override
  ConsumerState<_OrderPrepareBody> createState() => _OrderPrepareBodyState();
}

final class _OrderPrepareBodyState extends ConsumerState<_OrderPrepareBody> {
  bool _packMode = false;
  final TextEditingController _scanController = TextEditingController();

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  double _lineTotal(OrderItemEntity item) => item.quantity * item.unitPrice;

  double _linesSum(List<OrderItemEntity> items) =>
      items.fold<double>(0, (a, i) => a + _lineTotal(i));

  double _packProgressValue(Map<int, double> scanned, List<OrderItemEntity> items) {
    if (items.isEmpty) return 0;
    double num = 0;
    double den = 0;
    for (final i in items) {
      den += i.quantity;
      num += (scanned[i.id] ?? 0).clamp(0, i.quantity);
    }
    return den <= 0 ? 0 : (num / den).clamp(0, 1);
  }

  int _completedLineCount(Map<int, double> scanned, List<OrderItemEntity> items) {
    var c = 0;
    for (final i in items) {
      if ((scanned[i.id] ?? 0) >= i.quantity) c++;
    }
    return c;
  }

  bool _isRefundedStatus(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    return s.contains('refunded') || s.contains('iade');
  }

  String _packLineLabel(OrderItemEntity item, double scanned) {
    if (scanned <= 0) return 'Bekliyor';
    if (scanned < item.quantity) return 'Eksik';
    if (scanned > item.quantity) return 'Fazla';
    return 'Tamam';
  }

  Color _packLineColor(BuildContext context, OrderItemEntity item, double scanned) {
    final scheme = Theme.of(context).colorScheme;
    if (scanned <= 0) return scheme.outline;
    if (scanned < item.quantity) return scheme.tertiary;
    if (scanned > item.quantity) return scheme.error;
    return scheme.primary;
  }

  Future<void> _applyScan(String raw) async {
    final scan = OrderPackMatcher.normalizeScanInput(raw);
    if (scan.isEmpty) return;

    final items = widget.order.items;
    // Yalnizca bu siparis kalemleriyle eslesir; sipariste yoksa hicbir satira eklenmez.
    var matches = OrderPackMatcher.matchingLinesForOrderPack(scan, items);
    final allowedLineIds = items.map((e) => e.id).toSet();
    matches = matches.where((m) => allowedLineIds.contains(m.id)).toList();

    final notifier = ref.read(packProgressProvider(widget.order.id).notifier);

    if (matches.isEmpty) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bu urun bu siparis listesinde yok. '
                  'Sadece sipariste yer alan barkod / stok kodlari sayilir.',
                  style: TextStyle(
                    height: 1.25,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (matches.length == 1) {
      await notifier.incrementLine(matches.first.id, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eklendi: ${matches.first.name}')),
      );
      return;
    }

    if (!mounted) return;
    final picked = await showModalBottomSheet<OrderItemEntity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.5;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Birden fazla urun eslesti',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final m = matches[index];
                      return ListTile(
                        title: Text(
                          m.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Barkod: ${m.barcode}\nStok: ${m.stockCode}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.of(ctx).pop(m),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      await notifier.incrementLine(picked.id, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eklendi: ${picked.name}')),
      );
    }
  }

  Future<void> _openPackScanner() async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
    var locked = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(ctx).bottom,
          ),
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Barkod okut'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                Expanded(
                  child: MobileScanner(
                    controller: controller,
                    onDetect: (capture) async {
                      if (locked) return;
                      final raw = capture.barcodes.isEmpty
                          ? ''
                          : (capture.barcodes.first.rawValue ?? '');
                      final code = raw.trim();
                      if (code.isEmpty) return;
                      locked = true;
                      await controller.stop();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _scanController.text = code;
                      await _applyScan(code);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    await controller.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _confirmAndSubmitToSystem(OrderEntity order) async {
    if (_isRefundedStatus(order.status)) {
      _showErrorSnackBar(
        'Iade edilen siparislerde toplama modu kullanilamaz.',
      );
      return;
    }

    final scanned = ref.read(packProgressProvider(order.id));
    final validationResult = validatePackQuantities(scanned, order.items);

    switch (validationResult) {
      case PackQuantityResult.missing:
        _showErrorSnackBar(
          'Eksik urun okuttunuz. Lutfen tum urunleri tamamlayin.',
        );
        return;
      case PackQuantityResult.excess:
        _showErrorSnackBar(
          'Fazla urun okuttunuz. Lutfen siparisi kontrol edin.',
        );
        return;
      case PackQuantityResult.equal:
        break;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misin?'),
        content: const Text(
          'Toplama tamamlandi. Siparis durumunu sisteme gondermek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(submitOrderStatusProvider(order.id).notifier)
        .submit(deliveryTypeRaw: order.deliveryTypeRaw);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final scanned = ref.watch(packProgressProvider(order.id));
    final submitState = ref.watch(submitOrderStatusProvider(order.id));
    final theme = Theme.of(context);

    final linesSum = _linesSum(order.items);
    final finalAmt = order.finalAmount;
    final mismatch = finalAmt != null && (linesSum - finalAmt).abs() > 0.01;

    ref.listen<AsyncValue<void>>(submitOrderStatusProvider(order.id), (
      previous,
      next,
    ) {
      if (previous?.isLoading != true) return;
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      next.whenOrNull(
        data: (_) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Durum basariyla sisteme gonderildi.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        error: (error, _) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Sisteme gonderilemedi: $error'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    final isPackModeAllowed = !_isRefundedStatus(order.status);
    final isPackModeActive = _packMode && isPackModeAllowed;
    final packValidation = validatePackQuantities(scanned, order.items);
    final isExactMatch = packValidation == PackQuantityResult.equal;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _OrderSummaryCard(
            order: order,
            linesSum: linesSum,
            linesMismatch: mismatch,
          ),
        ),
        if (order.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Toplama modu',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch(
                            value: isPackModeActive,
                            onChanged: isPackModeAllowed
                                ? (v) => setState(() => _packMode = v)
                                : null,
                          ),
                        ],
                      ),
                      if (!isPackModeAllowed)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Iade edilen siparislerde toplama modu kapali.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isPackModeActive) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _packProgressValue(scanned, order.items),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Satir: ${_completedLineCount(scanned, order.items)} / ${order.items.length}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (isExactMatch)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Tum kalemler tamam (beklenen adet).',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _scanController,
                                decoration: const InputDecoration(
                                  labelText: 'Barkod / stok kodu',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: _applyScan,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _applyScan(_scanController.text),
                              child: const Text('Ekle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _openPackScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Kamera ile okut'),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isExactMatch && !submitState.isLoading
                                ? () => _confirmAndSubmitToSystem(order)
                                : null,
                            icon: submitState.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(
                              submitState.isLoading
                                  ? 'Sisteme Gonderiliyor...'
                                  : 'Sisteme Gonder',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                  final s = scanned[item.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderLineCard(
                      orderId: order.id,
                      item: item,
                      packMode: isPackModeActive,
                      scannedCount: s,
                      packStatusLabel: _packLineLabel(item, s),
                      packStatusColor: _packLineColor(context, item, s),
                    ),
                  );
                },
                childCount: order.items.length,
              ),
            ),
          ),
        if (order.shippingAddress != null && !order.shippingAddress!.isEmpty)
          SliverToBoxAdapter(
            child: _ShippingCard(address: order.shippingAddress!),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

final class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.order,
    required this.linesSum,
    required this.linesMismatch,
  });

  final OrderEntity order;
  final double linesSum;
  final bool linesMismatch;

  static String _money(double v) => '${v.toStringAsFixed(2)} TL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = order.finalAmount != null
        ? _money(order.finalAmount!)
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Kalemler toplami',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  _money(linesSum),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (linesMismatch)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Kalemler toplami ile siparis tutari farkli; iade veya indirim kontrol edin.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
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
  const _OrderLineCard({
    required this.orderId,
    required this.item,
    required this.packMode,
    required this.scannedCount,
    required this.packStatusLabel,
    required this.packStatusColor,
  });

  final int orderId;
  final OrderItemEntity item;
  final bool packMode;
  final double scannedCount;
  final String packStatusLabel;
  final Color packStatusColor;

  static String _money(double v) => '${v.toStringAsFixed(2)} TL';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qtyText = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);
    final lineTotal = item.quantity * item.unitPrice;
    final scannedText = scannedCount % 1 == 0
        ? scannedCount.toInt().toString()
        : scannedCount.toStringAsFixed(2);

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
                  const SizedBox(height: 8),
                  Text(
                    'Birim fiyat: ${_money(item.unitPrice)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'Kalem toplami: ${_money(lineTotal)} ($qtyText x ${_money(item.unitPrice)})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
                  if (packMode) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: packStatusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: packStatusColor),
                          ),
                          child: Text(
                            packStatusLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: packStatusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Okutulan: $scannedText',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Azalt',
                          onPressed: scannedCount > 0
                              ? () => ref
                                  .read(packProgressProvider(orderId).notifier)
                                  .incrementLine(item.id, -1)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton.filled(
                          tooltip: 'Arttir',
                          onPressed: () => ref
                              .read(packProgressProvider(orderId).notifier)
                              .incrementLine(item.id, 1),
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(width: 8),
                        if (scannedCount >= item.quantity)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                      ],
                    ),
                  ],
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
