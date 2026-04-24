import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/shipping_address_entity.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';
import 'package:mavikalem_app/features/orders/domain/repositories/orders_repository.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/order_prepare_page.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';
import 'package:mavikalem_app/features/orders/data/pack_progress_storage.dart';
import 'package:mavikalem_app/features/product_check/domain/entities/product_brief_entity.dart';
import 'package:mavikalem_app/features/product_check/domain/repositories/product_repository.dart';
import 'package:mavikalem_app/features/product_check/presentation/providers/product_check_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _FakeOrdersRepository implements OrdersRepository {
  _FakeOrdersRepository(this.order);

  final OrderEntity order;
  int? updatedOrderId;
  String? updatedDeliveryTypeRaw;
  OrderStatusTarget? updatedTarget;

  @override
  Future<List<OrderEntity>> getIncomingOrders({required int page}) async {
    return <OrderEntity>[order];
  }

  @override
  Future<OrderEntity> getOrderDetail(int orderId) async {
    return order;
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String? deliveryTypeRaw,
    OrderStatusTarget target = OrderStatusTarget.auto,
  }) async {
    updatedOrderId = orderId;
    updatedDeliveryTypeRaw = deliveryTypeRaw;
    updatedTarget = target;
  }
}

final class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.productsById);

  final Map<int, ProductBriefEntity> productsById;

  @override
  Future<List<ProductBriefEntity>> findByBarcode(String barcode) async {
    return const <ProductBriefEntity>[];
  }

  @override
  Future<List<ProductBriefEntity>> findByStockCode(String stockCode) async {
    return const <ProductBriefEntity>[];
  }

  @override
  Future<ProductBriefEntity> getById(int productId) async {
    return productsById[productId]!;
  }
}

// ignore_for_file: lines_longer_than_80_chars

OrderEntity _buildOrder({
  required int orderId,
  required Map<int, double> itemQtyById,
  String deliveryTypeRaw = 'kargo',
  String status = 'approved',
}) {
  final items = itemQtyById.entries
      .map(
        (e) => OrderItemEntity(
          id: e.key,
          productId: e.key,
          name: 'Kalem ${e.key}',
          stockCode: 'SKU-${e.key}',
          barcode: 'BARCODE${e.key}',
          quantity: e.value,
          unitPrice: 100,
          imageUrl: '',
        ),
      )
      .toList();

  return OrderEntity(
    id: orderId,
    orderNumber: 'MOCK-$orderId',
    customerName: 'Test Musteri',
    status: status,
    createdAt: DateTime(2026, 1, 1),
    items: items,
    shippingAddress: const ShippingAddressEntity(
      fullName: 'Test',
      phone: '',
      address: '',
      location: '',
      subLocation: '',
    ),
    finalAmount: null,
    paymentTypeName: 'Kart',
    deliveryTypeRaw: deliveryTypeRaw,
  );
}

Future<void> _pumpOrderPage(
  WidgetTester tester, {
  required OrderEntity order,
  required Map<String, Object> prefs,
  bool tapPackSwitch = true,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final fakeOrdersRepository = _FakeOrdersRepository(order);
  final fakeProductRepository = _FakeProductRepository(<int, ProductBriefEntity>{});

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ordersRepositoryProvider.overrideWithValue(fakeOrdersRepository),
        productRepositoryProvider.overrideWithValue(fakeProductRepository),
      ],
      child: MaterialApp(home: OrderPreparePage(orderId: order.id)),
    ),
  );
  await tester.pumpAndSettle();

  if (tapPackSwitch) {
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('shows confirm dialog and submits when pack complete', (
    tester,
  ) async {
    const orderId = 9001;
    final order = OrderEntity(
      id: orderId,
      orderNumber: 'MOCK-9001',
      customerName: 'Test Musteri',
      status: 'Hazirlaniyor',
      createdAt: DateTime(2026, 1, 1),
      items: const <OrderItemEntity>[
        OrderItemEntity(
          id: 1,
          productId: 101,
          name: 'Kalem 04',
          stockCode: 'ORDER-04',
          barcode: '693325661631904',
          quantity: 1,
          unitPrice: 100,
          imageUrl: '',
        ),
        OrderItemEntity(
          id: 2,
          productId: 102,
          name: 'Kalem 03',
          stockCode: 'ORDER-03',
          barcode: '693325661631903',
          quantity: 1,
          unitPrice: 100,
          imageUrl: '',
        ),
      ],
      shippingAddress: const ShippingAddressEntity(
        fullName: 'Test User',
        phone: '05555555555',
        address: 'Test Address',
        location: 'Istanbul',
        subLocation: 'Kadikoy',
      ),
      finalAmount: 200,
      paymentTypeName: 'Kart',
      deliveryTypeRaw: 'kargo',
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      PackProgressStorage.keyForOrder(orderId): jsonEncode(<String, num>{
        '1': 1,
        '2': 1,
      }),
    });

    final fakeOrdersRepository = _FakeOrdersRepository(order);
    final fakeProductRepository = _FakeProductRepository(<int, ProductBriefEntity>{
      101: const ProductBriefEntity(
        id: 101,
        name: 'Kalem 04',
        stockCode: 'ORDER-04',
        barcode: '693325661631904',
        stockAmount: 10,
      ),
      102: const ProductBriefEntity(
        id: 102,
        name: 'Kalem 03',
        stockCode: 'ORDER-03',
        barcode: '693325661631903',
        stockAmount: 10,
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ordersRepositoryProvider.overrideWithValue(fakeOrdersRepository),
          productRepositoryProvider.overrideWithValue(fakeProductRepository),
        ],
        child: const MaterialApp(home: OrderPreparePage(orderId: orderId)),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final submitButtonFinder = find.text('Sisteme Gonder');
    expect(submitButtonFinder, findsOneWidget);

    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Emin misin?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
    await tester.pumpAndSettle();

    expect(fakeOrdersRepository.updatedOrderId, orderId);
    expect(fakeOrdersRepository.updatedDeliveryTypeRaw, 'kargo');
    expect(
      find.text('Durum basariyla sisteme gonderildi.'),
      findsOneWidget,
    );
  });

  testWidgets('EKSIK okutmada buton disabled, dialog acilmaz', (
    tester,
  ) async {
    const orderId = 9002;
    final order = _buildOrder(
      orderId: orderId,
      itemQtyById: <int, double>{1: 2, 2: 3},
    );

    // Kalem 1: 1 okutulmus (eksik), Kalem 2: 3 okutulmus (tamam)
    await _pumpOrderPage(
      tester,
      order: order,
      prefs: <String, Object>{
        PackProgressStorage.keyForOrder(orderId): jsonEncode(<String, num>{
          '1': 1,
          '2': 3,
        }),
      },
    );

    expect(find.text('Sisteme Gonder'), findsOneWidget);

    // Disabled buton tapa yanit vermez → dialog acilmamali
    await tester.tap(find.text('Sisteme Gonder'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Emin misin?'), findsNothing);

    // Basarili gonderi mesaji da olmamali
    expect(find.text('Durum basariyla sisteme gonderildi.'), findsNothing);
  });

  testWidgets('FAZLA okutmada buton disabled, dialog acilmaz', (
    tester,
  ) async {
    const orderId = 9003;
    final order = _buildOrder(
      orderId: orderId,
      itemQtyById: <int, double>{1: 1, 2: 1},
    );

    // Her iki kalem de 2 okutulmus (fazla)
    await _pumpOrderPage(
      tester,
      order: order,
      prefs: <String, Object>{
        PackProgressStorage.keyForOrder(orderId): jsonEncode(<String, num>{
          '1': 2,
          '2': 2,
        }),
      },
    );

    expect(find.text('Sisteme Gonder'), findsOneWidget);

    // Disabled buton tapa yanit vermez → dialog acilmamali
    await tester.tap(find.text('Sisteme Gonder'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Emin misin?'), findsNothing);
    expect(find.text('Durum basariyla sisteme gonderildi.'), findsNothing);
  });

  testWidgets('ESIT okutmada dialog acilir ve submit calisir', (
    tester,
  ) async {
    const orderId = 9004;
    final order = _buildOrder(
      orderId: orderId,
      itemQtyById: <int, double>{1: 2, 2: 3},
    );

    // Tam esit miktar
    SharedPreferences.setMockInitialValues(<String, Object>{
      PackProgressStorage.keyForOrder(orderId): jsonEncode(<String, num>{
        '1': 2,
        '2': 3,
      }),
    });

    final fakeOrdersRepository = _FakeOrdersRepository(order);
    final fakeProductRepository = _FakeProductRepository(
      <int, ProductBriefEntity>{},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ordersRepositoryProvider.overrideWithValue(fakeOrdersRepository),
          productRepositoryProvider.overrideWithValue(fakeProductRepository),
        ],
        child: MaterialApp(home: OrderPreparePage(orderId: orderId)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Sisteme Gonder'), findsOneWidget);

    await tester.tap(find.text('Sisteme Gonder'));
    await tester.pumpAndSettle();

    // Tam esit → dialog acilmali
    expect(find.text('Emin misin?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Onayla'));
    await tester.pumpAndSettle();

    expect(fakeOrdersRepository.updatedOrderId, orderId);
    expect(
      find.text('Durum basariyla sisteme gonderildi.'),
      findsOneWidget,
    );
  });

  testWidgets('IADE siparis toplama moduna girmez', (tester) async {
    const orderId = 9005;
    final order = _buildOrder(
      orderId: orderId,
      itemQtyById: <int, double>{1: 1},
      status: 'refunded',
    );

    await _pumpOrderPage(
      tester,
      order: order,
      prefs: <String, Object>{
        PackProgressStorage.keyForOrder(orderId): jsonEncode(<String, num>{
          '1': 1,
        }),
      },
    );

    expect(find.text('Iade edilen siparislerde toplama modu kapali.'), findsOneWidget);
    expect(find.text('Barkod / stok kodu'), findsNothing);
    expect(find.text('Sisteme Gonder'), findsNothing);
  });
}
