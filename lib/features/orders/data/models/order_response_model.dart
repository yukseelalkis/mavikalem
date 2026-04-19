import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';

const String _orderItemPlaceholderImageUrl = 'https://via.placeholder.com/64';

DateTime? _parseOrderDateTime(Map<String, dynamic> json) {
  const keys = <String>[
    'createdAt',
    'created_at',
    'orderDate',
    'order_date',
    'updatedAt',
    'updated_at',
  ];

  for (final key in keys) {
    final raw = json[key];
    final parsed = _parseDynamicDate(raw);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _parseDynamicDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) {
    if (raw <= 0) return null;
    // Heuristic: IdeaSoft genelde saniye/ms unix timestamp dondurmez ama bazi API'ler dondurur.
    if (raw > 2000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
    }
    if (raw > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    }
    return null;
  }

  final text = raw.toString().trim();
  if (text.isEmpty) return null;

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  // "2025-12-18 13:02:00" gibi bosluklu formatlar
  final normalized = text.contains(' ') && !text.contains('T')
      ? text.replaceFirst(' ', 'T')
      : text;
  return DateTime.tryParse(normalized);
}

final class OrderResponseModel extends OrderEntity {
  const OrderResponseModel({
    required super.id,
    required super.orderNumber,
    required super.customerName,
    required super.status,
    required super.createdAt,
    required super.items,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['orderItems'] as List<dynamic>?) ??
        (json['items'] as List<dynamic>?) ??
        <dynamic>[];
    final firstName = (json['customerFirstname'] ?? '').toString().trim();
    final surName = (json['customerSurname'] ?? '').toString().trim();
    final fullName = '$firstName $surName'.trim();
    return OrderResponseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNumber:
          (json['orderNumber'] ?? json['order_number'] ?? json['id'] ?? '-')
              .toString(),
      customerName: fullName.isNotEmpty
          ? fullName
          : (json['customerName'] ??
                    json['customer_name'] ??
                    json['customer']?['name'] ??
                    '-')
                .toString(),
      status: (json['status'] ?? json['statusText'] ?? '-') as String,
      createdAt: _parseOrderDateTime(json),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItemResponseModel.fromJson)
          .toList(),
    );
  }
}

final class OrderItemResponseModel extends OrderItemEntity {
  const OrderItemResponseModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.stockCode,
    required super.quantity,
    required super.unitPrice,
    required super.imageUrl,
  });

  factory OrderItemResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderItemResponseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num? ?? json['product_id'] as num? ?? 0)
          .toInt(),
      name: (json['name'] ?? json['productName'] ?? '-') as String,
      stockCode: (json['stockCode'] ?? json['sku'] ?? json['productSku'] ?? '-')
          .toString(),
      quantity:
          (json['quantity'] as num? ?? json['productQuantity'] as num? ?? 1)
              .toDouble(),
      unitPrice:
          (json['unitPrice'] as num? ?? json['productPrice'] as num? ?? 0)
              .toDouble(),
      imageUrl:
          (json['imageUrl'] ?? json['image'] ?? _orderItemPlaceholderImageUrl)
              .toString(),
    );
  }
}
