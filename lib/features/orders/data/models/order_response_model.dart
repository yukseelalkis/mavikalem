import 'package:mavikalem_app/features/orders/domain/entities/order_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/shipping_address_entity.dart';

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

double? _parseMoney(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  final s = raw.toString().trim().replaceAll(',', '.');
  return double.tryParse(s);
}

String? _optionalTrimmedString(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

ShippingAddressEntity? _parseShipping(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final json = raw;
  final fn = (json['firstname'] ?? json['firstName'] ?? '').toString().trim();
  final ln = (json['lastname'] ?? json['lastName'] ?? '').toString().trim();
  var full = '$fn $ln'.trim();
  if (full.isEmpty) {
    full = _optionalTrimmedString(
          json['fullName'] ?? json['customerName'] ?? json['name'],
        ) ??
        '';
  }
  final phone =
      _optionalTrimmedString(json['phone'] ?? json['mobilePhone'] ?? json['gsm']) ??
      '';
  final address =
      _optionalTrimmedString(
        json['address'] ?? json['address1'] ?? json['addressLine'],
      ) ??
      '';
  final location =
      _optionalTrimmedString(
        json['location'] ?? json['city'] ?? json['province'],
      ) ??
      '';
  final subLocation =
      _optionalTrimmedString(
        json['subLocation'] ?? json['district'] ?? json['town'],
      ) ??
      '';

  final entity = ShippingAddressEntity(
    fullName: full,
    phone: phone,
    address: address,
    location: location,
    subLocation: subLocation,
  );
  return entity.isEmpty ? null : entity;
}

final class OrderResponseModel extends OrderEntity {
  const OrderResponseModel({
    required super.id,
    required super.orderNumber,
    required super.customerName,
    required super.status,
    required super.createdAt,
    required super.items,
    super.shippingAddress,
    super.finalAmount,
    super.paymentTypeName,
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
      shippingAddress: _parseShipping(
        json['shippingAddress'] ?? json['shipping_address'],
      ),
      finalAmount: _parseMoney(json['finalAmount'] ?? json['final_amount']),
      paymentTypeName: _optionalTrimmedString(
        json['paymentTypeName'] ?? json['payment_type_name'],
      ),
    );
  }
}

final class OrderItemResponseModel extends OrderItemEntity {
  const OrderItemResponseModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.stockCode,
    required super.barcode,
    required super.quantity,
    required super.unitPrice,
    required super.imageUrl,
  });

  factory OrderItemResponseModel.fromJson(Map<String, dynamic> json) {
    var productId =
        (json['productId'] as num? ?? json['product_id'] as num? ?? 0).toInt();
    final nested = json['product'];
    if (nested is Map<String, dynamic>) {
      final nid = nested['id'];
      if (nid is num) {
        productId = nid.toInt();
      }
    }

    final barcodeRaw =
        (json['productBarcode'] ?? json['barcode'] ?? '').toString().trim();

    return OrderItemResponseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: productId,
      name: (json['productName'] ?? json['name'] ?? '-').toString(),
      stockCode:
          (json['productSku'] ?? json['stockCode'] ?? json['sku'] ?? '-')
              .toString(),
      barcode: barcodeRaw.isEmpty ? '-' : barcodeRaw,
      quantity:
          (json['productQuantity'] as num? ?? json['quantity'] as num? ?? 1)
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
