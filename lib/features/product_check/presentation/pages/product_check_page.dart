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
  final TextEditingController _stockCodeController = TextEditingController();
  bool _isScannerVisible = false;
  String _lastScanned = '';

  @override
  void dispose() {
    _stockCodeController.dispose();
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
                    controller: _stockCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Stok kodu giriniz',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchByStockCode(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searchByStockCode,
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
                        ref
                            .read(productLookupProvider.notifier)
                            .searchByBarcode(code);
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
                  return const Center(
                    child: Text(
                      'Barkod okutun veya stok kodu ile arama yapin.',
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

  void _searchByStockCode() {
    final query = _stockCodeController.text.trim();
    if (query.isEmpty) return;
    ref.read(productLookupProvider.notifier).searchByStockCode(query);
  }
}

final class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({required this.product});

  final ProductBriefEntity product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: product.imageUrl.isEmpty
            ? const Icon(Icons.inventory_2_outlined)
            : Image.network(
                product.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.inventory_2_outlined),
              ),
        title: Text(product.name),
        subtitle: Text(
          'Stok: ${product.stockCode}\nBarkod: ${product.barcode}\nMiktar: ${product.stockAmount}',
        ),
      ),
    );
  }
}
