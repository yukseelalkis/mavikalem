import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
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
  String _lastScanned = '';
  /// En az bir arama/kamera okumasi yapildi mi (bos sonuc mesaji icin).
  bool _lookupAttempted = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      hintText:
                          'Ayni kutuya yazin; sistem ikisinde de arar',
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
                    onPressed: () {
                      setState(() {
                        _isScannerVisible = !_isScannerVisible;
                      });
                    },
                    icon: Icon(
                      _isScannerVisible
                          ? Icons.visibility_off
                          : Icons.qr_code_scanner,
                    ),
                    label: Text(
                      _isScannerVisible ? 'Kamerayi Kapat' : 'Barkod Oku',
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
                        final code = capture.barcodes.isEmpty
                            ? ''
                            : (capture.barcodes.first.rawValue ?? '');
                        if (code.isEmpty || code == _lastScanned) return;
                        _lastScanned = code;
                        setState(() => _lookupAttempted = true);
                        ref
                            .read(productLookupProvider.notifier)
                            .searchByQuery(code);
                      },
                    ),
                    const ScannerOverlay(),
                  ],
                ),
              ),
            ),
          Expanded(
            child: lookupAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Urun aranirken hata: $error')),
              data: (products) {
                if (products.isEmpty) {
                  if (!_lookupAttempted) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Stok kodu veya barkod yazip Ara\'ya basin; '
                          'isterseniz asagidan barkod okutun. '
                          'Sistem her iki alanda da ayni metni arar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Urun bulunamadi',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Girdiginiz deger stok kodu veya barkod ile '
                            'eslesen bir urun bulunamadi.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            memCacheWidth: (MediaQuery.sizeOf(context).width *
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
                                color: theme.colorScheme.surface
                                    .withValues(alpha: 0.92),
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
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
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
                const SizedBox(height: 12),
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
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
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
    final valueStyle =
        emphasize
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
