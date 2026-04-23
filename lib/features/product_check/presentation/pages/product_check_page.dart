import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mavikalem_app/core/widgets/delivery_type_badge.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/presentation/constants/stock_thresholds.dart';
import 'package:mavikalem_app/features/product_check/presentation/providers/product_check_providers.dart';
import 'package:mavikalem_app/features/product_check/presentation/widgets/scanner_overlay.dart';

final class ProductCheckPage extends ConsumerStatefulWidget {
  const ProductCheckPage({super.key});

  @override
  ConsumerState<ProductCheckPage> createState() => _ProductCheckPageState();
}

final class _ProductCheckPageState extends ConsumerState<ProductCheckPage> {
  final TextEditingController _queryController = TextEditingController();
  bool _isScannerVisible = false;

  /// Acik kamera oturumunda ilk gecerli okuma islendiyse true (cift tetik / cift istek onlemi).
  bool _scanLocked = false;

  /// En az bir arama/kamera okumasi yapildi mi (bos sonuc mesaji icin).
  bool _lookupAttempted = false;

  /// Aynı arama sonucu için tekrar tekrar bottom sheet açılmasın diye açılan liste.
  List<int>? _variantSheetSignature;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ProductBriefEntity>>>(productLookupProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (products) {
          if (products.isEmpty) {
            if (_lookupAttempted) _showNotFoundSnackBar();
            _variantSheetSignature = null;
            return;
          }
          if (products.length > 1) {
            _maybeShowVariantSheet(products);
          } else {
            _variantSheetSignature = null;
          }
        },
      );
    });

    final lookupAsync = ref.watch(productLookupProvider);
    final scannerController = ref.watch(scannerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Urun Kontrol')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'Stok kodu veya barkod',
                      hintText: 'Ayni kutuya yazin; sistem ikisinde de arar',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchByQuery(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searchByQuery,
                  child: const Text('Ara'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleScanner,
                    icon: Icon(
                      _isScannerVisible
                          ? Icons.visibility_off
                          : Icons.qr_code_scanner,
                    ),
                    label: Text(
                      _isScannerVisible ? 'Kamerayi Kapat' : 'Kamera Ac',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isScannerVisible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: scannerController,
                      onDetect: (capture) {
                        unawaited(_onBarcodeDetected(capture));
                      },
                    ),
                    const ScannerOverlay(),
                  ],
                ),
              ),
            ),
          Expanded(
            child: lookupAsync.when(
              loading: () => _ProductCheckStateCard(
                icon: Icons.hourglass_top_rounded,
                title: 'Urun araniyor',
                body:
                    'Baglanti kuruluyor; stok kodu ve barkod sorgusu '
                    'sirasiyla yapiliyor.',
                showProgress: true,
              ),
              error: (error, _) => _ProductCheckStateCard(
                icon: Icons.cloud_off_rounded,
                title: 'Arama yapilamadi',
                body:
                    'Bir seyler ters gitti. Internet baglantinizi kontrol edin '
                    'veya biraz sonra tekrar deneyin.\n\n'
                    'Detay: $error',
                onRetry: _retryLookup,
              ),
              data: (products) {
                if (products.isEmpty) {
                  if (!_lookupAttempted) {
                    return _ProductCheckStateCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Nasil kullanilir?',
                      body:
                          'Stok kodu veya barkodu yazip Ara\'ya basin; '
                          'veya Kamera Ac ile tek seferlik okutun '
                          '(okuma sonrasi kamera kapanir). '
                          'Sistem once stok kodunu, sonra barkodu arar.',
                    );
                  }
                  return _ProductCheckStateCard(
                    icon: Icons.search_off_rounded,
                    title: 'Urun bulunamadi',
                    body:
                        'Girdiginiz deger stok kodu veya barkod ile '
                        'eslesen bir urun bulunamadi. Kodu kontrol edip '
                        'yeniden arayabilirsiniz.',
                    onRetry: _retryLookup,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _ProductResultCard(product: products[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _searchByQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() => _lookupAttempted = true);
    ref.read(productLookupProvider.notifier).searchByQuery(query);
  }

  void _retryLookup() {
    final q = _queryController.text.trim();
    ref.invalidate(productLookupProvider);
    if (q.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(productLookupProvider.notifier).searchByQuery(q);
      });
    } else {
      setState(() => _lookupAttempted = false);
    }
  }

  Future<void> _toggleScanner() async {
    final controller = ref.read(scannerControllerProvider);

    if (_isScannerVisible) {
      await controller.stop();
      if (!mounted) return;
      setState(() {
        _isScannerVisible = false;
        _scanLocked = false;
      });
      return;
    }

    _scanLocked = false;
    setState(() => _isScannerVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.start();
    });
  }

  void _showNotFoundSnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Ürün bulunamadı'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _maybeShowVariantSheet(List<ProductBriefEntity> products) {
    final signature = products.map((p) => p.id).toList(growable: false);
    if (_variantSheetSignature != null &&
        _listEquals(_variantSheetSignature!, signature)) {
      return;
    }
    _variantSheetSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => _VariantPickerSheet(
          products: products,
          onSelect: (selected) {
            Navigator.of(sheetContext).pop();
            ref
                .read(productLookupProvider.notifier)
                .selectSingleProduct(selected);
          },
        ),
      );
    });
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_scanLocked) return;

    final raw = capture.barcodes.isEmpty
        ? ''
        : (capture.barcodes.first.rawValue ?? '');
    final code = raw.trim();
    if (code.isEmpty) return;

    _scanLocked = true;

    final controller = ref.read(scannerControllerProvider);
    await controller.stop();

    if (!mounted) return;

    setState(() {
      _isScannerVisible = false;
      _queryController.text = code;
      _lookupAttempted = true;
    });

    ref.read(productLookupProvider.notifier).searchByQuery(code);
  }
}

final class _ProductCheckStateCard extends StatelessWidget {
  const _ProductCheckStateCard({
    required this.icon,
    required this.title,
    required this.body,
    this.showProgress = false,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool showProgress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProgress)
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: scheme.primary,
                    ),
                  )
                else
                  Icon(icon, size: 52, color: scheme.primary),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _StockStatusRow extends StatelessWidget {
  const _StockStatusRow({required this.stockAmount});

  final double stockAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    late final String label;
    late final IconData icon;
    late final Color color;

    if (stockAmount <= 0) {
      label = 'Stokta yok';
      icon = Icons.remove_shopping_cart_outlined;
      color = scheme.error;
    } else if (stockAmount <= StockThresholds.lowStockMax) {
      label = 'Dusuk stok';
      icon = Icons.warning_amber_rounded;
      color = scheme.tertiary;
    } else {
      label = 'Stokta var';
      icon = Icons.check_circle_outline_rounded;
      color = scheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: Icon(icon, size: 18, color: color),
          label: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          backgroundColor: color.withValues(alpha: 0.1),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

final class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({required this.product});

  final ProductBriefEntity product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: InkWell(
              onTap: product.imageUrl.isEmpty
                  ? null
                  : () => _openImagePreview(context, product.imageUrl),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 72,
                          color: theme.colorScheme.outline,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.contain,
                            memCacheWidth:
                                (MediaQuery.sizeOf(context).width *
                                        MediaQuery.of(context).devicePixelRatio)
                                    .round(),
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_in_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Buyut',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                DeliveryTypeBadge(rawValue: product.deliveryTypeRaw),
                const SizedBox(height: 10),
                _StockStatusRow(stockAmount: product.stockAmount),
                _InfoLine(
                  icon: Icons.payments_outlined,
                  label: 'Liste fiyati',
                  value: product.price == null
                      ? '-'
                      : '${product.price!.toStringAsFixed(2)} TL',
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.numbers_rounded,
                  label: 'Stok kodu',
                  value: product.stockCode,
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Barkod',
                  value: product.barcode,
                  emphasize: true,
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.inventory_2_outlined,
                  label: 'Depo miktari',
                  value: product.stockAmount % 1 == 0
                      ? product.stockAmount.toInt().toString()
                      : product.stockAmount.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(ctx).top + 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Positioned(
                bottom: MediaQuery.paddingOf(ctx).bottom + 16,
                left: 0,
                right: 0,
                child: Text(
                  'Parmakla yaklastir / uzaklastir',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          )
        : theme.textTheme.bodyLarge;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(value, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}

final class _VariantPickerSheet extends StatelessWidget {
  const _VariantPickerSheet({required this.products, required this.onSelect});

  final List<ProductBriefEntity> products;
  final ValueChanged<ProductBriefEntity> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaBottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaBottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Varyant seçin',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Taradığınız barkod birden fazla varyanta uyuyor.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final subtitle = <String>[
                      if (product.barcode.trim().isNotEmpty)
                        'Barkod: ${product.barcode}',
                      if (product.stockCode.trim().isNotEmpty)
                        'Stok: ${product.stockCode}',
                    ].join(' • ');

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
                      title: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onSelect(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
