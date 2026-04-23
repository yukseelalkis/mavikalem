import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';
import 'package:mavikalem_app/features/product_check/presentation/pages/product_check_page.dart';
import 'package:mavikalem_app/features/product_check/presentation/providers/product_check_providers.dart';
import 'package:mavikalem_app/shared/presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: <Override>[
        productRepositoryProvider.overrideWithValue(_ManualProductRepository()),
      ],
      child: const _ManualProductCheckApp(),
    ),
  );
}

final class _ManualProductCheckApp extends StatelessWidget {
  const _ManualProductCheckApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ProductCheckPage(),
    );
  }
}

final class _ManualProductRepository implements ProductRepository {
  static final List<ProductBriefEntity> _products = <ProductBriefEntity>[
    ProductBriefEntity(
      id: 101,
      name: 'Siparis 04 - Kirmizi Kalem',
      stockCode: 'ORDER-04',
      barcode: '693325661631904',
      stockAmount: 15,
      imageUrls: <String>[],
      deliveryTypeRaw: 'cargo',
    ),
    ProductBriefEntity(
      id: 102,
      name: 'Siparis 03 - Mavi Kalem',
      stockCode: 'ORDER-03',
      barcode: '693325661631903',
      stockAmount: 9,
      imageUrls: <String>[],
      deliveryTypeRaw: 'cargo',
    ),
    ProductBriefEntity(
      id: 103,
      name: 'Siparis 02 - Siyah Kalem',
      stockCode: 'ORDER-02',
      barcode: '693325661631902',
      stockAmount: 5,
      imageUrls: <String>[],
      deliveryTypeRaw: 'cargo',
    ),
  ];

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    final query = barcode.trim();
    if (query.isEmpty) return const <ProductBriefEntity>[];

    final exact = _products.where((p) => p.barcode == query).toList();
    if (exact.isNotEmpty) return exact;

    return _products.where((p) => p.barcode.startsWith(query)).toList();
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) async {
    final query = stockCode.trim().toUpperCase();
    if (query.isEmpty) return const <ProductBriefEntity>[];
    return _products
        .where((p) => p.stockCode.toUpperCase().contains(query))
        .toList();
  }

  @override
  Future<ProductBriefEntity> getById(int productId) async {
    return _products.firstWhere((p) => p.id == productId);
  }
}
