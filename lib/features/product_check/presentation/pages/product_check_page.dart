import 'dart:async';

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

  /// Acik kamera oturumunda ilk gecerli okuma islendiyse true (cift tetik / cift istek onlemi).
  bool _scanLocked = false;

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
                          'veya Kamera Ac ile tek seferlik okutun '
                          '(okuma sonrasi kamera kapanir). '
                          'Sistem once stok kodunu, sonra barkodu arar.',
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

final class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({required this.product});

  final ProductBriefEntity product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = product.imageUrls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();

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
            child: _ProductImageCarousel(imageUrls: urls),
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
}

final class _ProductImageCarousel extends StatefulWidget {
  const _ProductImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

final class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late final PageController _pageController;
  var _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.imageUrls;

    if (urls.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 72,
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final memCacheW =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.of(context).devicePixelRatio)
            .round();

    final showDots = urls.length > 1;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: urls[index],
                fit: BoxFit.contain,
                memCacheWidth: memCacheW,
                placeholder: (_, __) => Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
                errorWidget: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                ),
              );
            },
          ),
          if (showDots)
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _pageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.45),
                    ),
                  );
                }),
              ),
            ),
          Positioned(
            right: 8,
            bottom: showDots ? 12 : 8,
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    _showProductImageGallery(context, urls, _pageIndex),
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
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showProductImageGallery(
  BuildContext context,
  List<String> urls,
  int initialIndex,
) {
  final safe = urls.where((u) => u.trim().isNotEmpty).toList(growable: false);
  if (safe.isEmpty) return;
  final i = initialIndex.clamp(0, safe.length - 1);

  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => _FullscreenProductGallery(
      urls: safe,
      initialIndex: i,
    ),
  );
}

final class _FullscreenProductGallery extends StatefulWidget {
  const _FullscreenProductGallery({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullscreenProductGallery> createState() =>
      _FullscreenProductGalleryState();
}

final class _FullscreenProductGalleryState extends State<_FullscreenProductGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.urls;
    final showDots = urls.length > 1;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: urls[index],
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      size: 72,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          if (showDots)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 56,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active ? Colors.white : Colors.white38,
                    ),
                  );
                }),
              ),
            ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 0,
            right: 0,
            child: Text(
              showDots
                  ? '${_index + 1} / ${urls.length} • Parmakla yaklastir'
                  : 'Parmakla yaklastir / uzaklastir',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
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
