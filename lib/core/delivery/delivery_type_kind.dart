import 'dart:convert' as convert;

enum DeliveryTypeKind { storePickup, cargo, unknown }

const List<String> _storeKeywords = <String>[
  'store',
  'pickup',
  'magaza',
  'magazadan teslim',
];

const List<String> _cargoKeywords = <String>['cargo', 'kargo', 'shipping'];

const List<String> _deliveryTypeKeys = <String>[
  'shipping_type',
  'shippingType',
  'delivery_type',
  'deliveryType',
  'shipment_type',
  'shipmentType',
  'teslimat_tipi',
  'teslimatTipi',
];

DeliveryTypeKind resolveDeliveryType(String? raw) {
  final normalized = normalizeDeliveryType(raw);
  if (normalized == null) return DeliveryTypeKind.unknown;

  if (_storeKeywords.any(normalized.contains)) {
    return DeliveryTypeKind.storePickup;
  }

  if (_cargoKeywords.any(normalized.contains)) {
    return DeliveryTypeKind.cargo;
  }

  return DeliveryTypeKind.unknown;
}

String? extractDeliveryTypeRaw(
  Map<String, dynamic> json, {
  Map<String, dynamic>? nestedMap,
}) {
  final direct = _firstNonEmptyDeliveryValue(json, _deliveryTypeKeys);
  if (direct != null) return direct;
  if (nestedMap == null) return null;
  return _firstNonEmptyDeliveryValue(nestedMap, _deliveryTypeKeys);
}

/// Sipariş JSON'undan teslimat tipini çıkarır.
///
/// Öncelik sırası:
/// 1. `shippingProviderCode`, `shippingProviderName`, `shippingCompanyName`,
///    `shippingPaymentType` alanları kargo/mağaza kelimesi içeriyorsa onu kullan.
/// 2. Provider bilgisi yoksa ve `orderDetails` içinde `shipping_location_id`
///    varsa mağaza teslim olarak işaretle (fallback).
/// 3. Genel `shipping_type` / `delivery_type` anahtarları.
String? extractOrderDeliveryTypeRaw(Map<String, dynamic> json) {
  final providerText = _readOrderProviderText(json);
  final providerKind = resolveDeliveryType(providerText);
  if (providerKind == DeliveryTypeKind.cargo) {
    return providerText;
  }
  if (providerKind == DeliveryTypeKind.storePickup) {
    return providerText;
  }

  if (_hasStorePickupLocationId(json)) {
    return 'store_pickup';
  }

  final generic = extractDeliveryTypeRaw(json);
  if (generic != null) return generic;

  return null;
}

bool _hasStorePickupLocationId(Map<String, dynamic> json) {
  final rawDetails = json['orderDetails'] ?? json['order_details'];
  if (rawDetails is! List) return false;

  for (final entry in rawDetails) {
    if (entry is! Map<String, dynamic>) continue;

    final key = _stringFromDynamic(entry['varKey'] ?? entry['var_key']);
    final value = entry['varValue'] ?? entry['var_value'];

    if (key != null && key.toLowerCase().contains('shipping_location_id')) {
      final parsed = _stringFromDynamic(value);
      if (parsed != null && parsed.trim().isNotEmpty) return true;
    }

    if (value is String) {
      final parsed = _tryParseJsonMap(value);
      if (parsed != null && _mapHasShippingLocationId(parsed)) {
        return true;
      }
      if (value.toLowerCase().contains('shipping_location_id')) {
        return true;
      }
    } else if (value is Map<String, dynamic>) {
      if (_mapHasShippingLocationId(value)) return true;
    }
  }

  return false;
}

bool _mapHasShippingLocationId(Map<String, dynamic> map) {
  for (final entry in map.entries) {
    if (entry.key.toLowerCase() == 'shipping_location_id') {
      final v = _stringFromDynamic(entry.value);
      if (v != null && v.isNotEmpty) return true;
    }
    if (entry.value is Map<String, dynamic>) {
      if (_mapHasShippingLocationId(entry.value as Map<String, dynamic>)) {
        return true;
      }
    }
  }
  return false;
}

Map<String, dynamic>? _tryParseJsonMap(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('{')) return null;
  try {
    final decoded = convert.json.decode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    return null;
  }
  return null;
}

String? _readOrderProviderText(Map<String, dynamic> json) {
  final parts = <String>[
    for (final key in const <String>[
      'shippingProviderCode',
      'shipping_provider_code',
      'shippingProviderName',
      'shipping_provider_name',
      'shippingCompanyName',
      'shipping_company_name',
      'shippingPaymentType',
      'shipping_payment_type',
    ])
      _stringFromDynamic(json[key]) ?? '',
  ].where((s) => s.trim().isNotEmpty).toList();

  if (parts.isEmpty) return null;
  return parts.join(' ');
}

String? normalizeDeliveryType(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  return trimmed
      .toLowerCase()
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

String? _firstNonEmptyDeliveryValue(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final raw = _stringFromDynamic(map[key]);
    if (raw != null) return raw;
  }
  return null;
}

String? _stringFromDynamic(dynamic value) {
  if (value == null) return null;

  if (value is Map<String, dynamic>) {
    for (final nestedKey in const <String>['code', 'type', 'name', 'value']) {
      final nestedValue = _stringFromDynamic(value[nestedKey]);
      if (nestedValue != null) return nestedValue;
    }
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty || text == '-') return null;
  return text;
}
