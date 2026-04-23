import 'package:flutter/material.dart';

/// IdeaSoft API'den gelen ham sipariş durumu (`status`) değerlerini
/// Türkçe karşılıklarına çevirir.
///
/// Tüm eşleştirmeler IdeaSoft panel standartlarına göre tanımlanmıştır.
/// Bilinmeyen değerler orijinal ham değerle döndürülür; böylece yeni
/// statüler eklendiğinde UI yine de bir şeyler gösterir.
final class OrderStatusLocalization {
  const OrderStatusLocalization._();

  static const Map<String, String> _map = <String, String>{
    'approved': 'Onaylandı',
    'being_prepared': 'Hazırlanıyor',
    'shipped': 'Kargoya Verildi',
    'delivered': 'Teslim Edildi',
    'refunded': 'İade Edildi',
    'canceled': 'İptal Edildi',
    'cancelled': 'İptal Edildi',
    'waiting_for_approval': 'Onay Bekliyor',
    'supplying': 'Tedarik Sürecinde',
    'waiting_for_payment': 'Ödeme Bekleniyor',
  };

  /// Ham API status değerini Türkçe etikete çevirir.
  ///
  /// Eşleşme için önce tam kelime kontrolü (`_map` lookup) yapılır.
  /// Bulunamazsa [_fallbackFromRaw] ile kısmi eşleştirme denenir.
  /// Hâlâ eşleşme yoksa ham değer döndürülür.
  static String toTurkish(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return 'Bilinmiyor';

    final exact = _map[trimmed.toLowerCase()];
    if (exact != null) return exact;

    return _fallbackFromRaw(trimmed) ?? trimmed;
  }

  /// [OrderStatusDisplayStyle] ile birlikte renk bilgisini de döndürür.
  static OrderStatusDisplayStyle styleForRaw(String raw) {
    final label = toTurkish(raw);
    final s = raw.trim().toLowerCase();

    if (s == 'approved' || s.contains('onay')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.green);
    }
    if (s == 'being_prepared' ||
        s.contains('hazirlan') ||
        s.contains('prepar')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.blue);
    }
    if (s == 'delivered' || s.contains('teslim')) {
      return OrderStatusDisplayStyle(
        label: label,
        color: Colors.green.shade800,
      );
    }
    if (s == 'shipped' || s.contains('kargo') || s.contains('shipped')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.indigo);
    }
    if (s == 'refunded' || s.contains('iade') || s.contains('refund')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.orange);
    }
    if (s == 'canceled' || s == 'cancelled' || s.contains('cancel')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.red);
    }
    if (s == 'waiting_for_approval' || s.contains('waiting_for_approval')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.amber.shade700);
    }
    if (s == 'supplying' || s.contains('tedarik') || s.contains('supply')) {
      return OrderStatusDisplayStyle(label: label, color: Colors.purple);
    }
    if (s == 'waiting_for_payment' || s.contains('payment')) {
      return OrderStatusDisplayStyle(
        label: label,
        color: Colors.deepOrange,
      );
    }

    return OrderStatusDisplayStyle(label: label, color: Colors.blueGrey);
  }

  static String? _fallbackFromRaw(String raw) {
    final s = raw.toLowerCase();
    for (final entry in _map.entries) {
      if (s.contains(entry.key)) return entry.value;
    }
    return null;
  }
}

/// Status badgesi için gerekli bilgileri taşır (label + renk).
final class OrderStatusDisplayStyle {
  const OrderStatusDisplayStyle({required this.label, required this.color});

  final String label;
  final Color color;
}
