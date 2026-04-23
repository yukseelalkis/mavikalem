import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/shipping_address_entity.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/order_prepare_page.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';
import 'package:mavikalem_app/features/product_check/presentation/providers/product_check_providers.dart';
import 'package:mavikalem_app/shared/presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: <Override>[
        ordersRepositoryProvider.overrideWithValue(_ManualOrdersRepository()),
        productRepositoryProvider.overrideWithValue(_ManualProductRepository()),
      ],
      child: const _ManualOrderPickApp(),
    ),
  );
}

final class _ManualOrderPickApp extends StatelessWidget {
  const _ManualOrderPickApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const OrderPreparePage(orderId: 9001),
    );
  }
}

final class _ManualOrdersRepository implements OrdersRepository {
  static final OrderEntity _mockOrder = OrderEntity(
    id: 9001,
    orderNumber: 'MOCK-9001',
    customerName: 'Test Musteri',
    status: 'Hazirlaniyor',
    createdAt: DateTime.now(),
    items: <OrderItemEntity>[
      OrderItemEntity(
        id: 2001,
        productId: 101,
        name: 'Siparis 04 - Kirmizi Kalem',
        stockCode: 'ORDER-04',
        barcode: '693325661631904',
        quantity: 1,
        unitPrice: 120,
        imageUrl: '',
      ),
      OrderItemEntity(
        id: 2002,
        productId: 102,
        name: 'Siparis 03 - Mavi Kalem',
        stockCode: 'ORDER-03',
        barcode: '693325661631903',
        quantity: 1,
        unitPrice: 118,
        imageUrl: '',
      ),
      OrderItemEntity(
        id: 2003,
        productId: 103,
        name: 'Siparis 02 - Siyah Kalem',
        stockCode: 'ORDER-02',
        barcode: '693325661631902',
        quantity: 1,
        unitPrice: 115,
        imageUrl: '',
      ),
    ],
    shippingAddress: const ShippingAddressEntity(
      fullName: 'Depo Test Kullanici',
      phone: '05555555555',
      address: 'Test Mahallesi 1. Sokak No:10',
      location: 'Istanbul',
      subLocation: 'Kadikoy',
    ),
    finalAmount: 353,
    paymentTypeName: 'Kredi Karti',
    deliveryTypeRaw: 'cargo',
  );

  @override
  Future<List<OrderEntity>> getIncomingOrders({required int page}) async {
    if (page > 1) return const <OrderEntity>[];
    return <OrderEntity>[_mockOrder];
  }

  @override
  Future<OrderEntity> getOrderDetail(int orderId) async {
    if (orderId == _mockOrder.id) return _mockOrder;
    throw StateError('Mock siparis bulunamadi: $orderId');
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String? deliveryTypeRaw,
  }) async {}
}

final class _ManualProductRepository implements ProductRepository {
  static final List<ProductBriefEntity> _products = <ProductBriefEntity>[
    ProductBriefEntity(
      id: 101,
      name: 'Siparis 04 - Kirmizi Kalem',
      stockCode: 'ORDER-04',
      barcode: '693325661631904',
      stockAmount: 20,
      imageUrls: <String>[],
      deliveryTypeRaw: 'cargo',
    ),
    ProductBriefEntity(
      id: 102,
      name: 'Siparis 03 - Mavi Kalem',
      stockCode: 'ORDER-03',
      barcode: '693325661631903',
      stockAmount: 18,
      imageUrls: <String>[],
      deliveryTypeRaw: 'cargo',
    ),
    ProductBriefEntity(
      id: 103,
      name: 'Siparis 02 - Siyah Kalem',
      stockCode: 'ORDER-02',
      barcode: '693325661631902',
      stockAmount: 16,
      imageUrls: <String>[],
      deliveryTypeRaw: 'cargo',
    ),
  ];

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    final query = barcode.trim();
    if (query.isEmpty) return const <ProductBriefEntity>[];
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
