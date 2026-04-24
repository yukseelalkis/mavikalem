import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_localization.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';

void main() {
  group('OrderStatusLocalization.toTurkish', () {
    final cases = <String, String>{
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

    for (final entry in cases.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(OrderStatusLocalization.toTurkish(entry.key), entry.value);
      });
    }

    test('empty string returns Bilinmiyor', () {
      expect(OrderStatusLocalization.toTurkish(''), 'Bilinmiyor');
    });

    test('dash returns Bilinmiyor', () {
      expect(OrderStatusLocalization.toTurkish('-'), 'Bilinmiyor');
    });

    test('unknown value returns raw value as fallback', () {
      expect(
        OrderStatusLocalization.toTurkish('some_future_status'),
        'some_future_status',
      );
    });

    test('case-insensitive exact match', () {
      expect(OrderStatusLocalization.toTurkish('Approved'), 'Onaylandı');
    });

    test('whitespace is trimmed', () {
      expect(OrderStatusLocalization.toTurkish('  delivered  '), 'Teslim Edildi');
    });
  });

  group('OrderStatusLocalization.styleForRaw', () {
    test('approved returns green color', () {
      final style = OrderStatusLocalization.styleForRaw('approved');
      expect(style.label, 'Onaylandı');
      expect(style.color, Colors.green);
    });

    test('being_prepared returns blue color', () {
      final style = OrderStatusLocalization.styleForRaw('being_prepared');
      expect(style.label, 'Hazırlanıyor');
      expect(style.color, Colors.blue);
    });

    test('delivered returns dark green color', () {
      final style = OrderStatusLocalization.styleForRaw('delivered');
      expect(style.label, 'Teslim Edildi');
      expect(style.color, Colors.green.shade800);
    });

    test('shipped returns indigo color', () {
      final style = OrderStatusLocalization.styleForRaw('shipped');
      expect(style.label, 'Kargoya Verildi');
      expect(style.color, Colors.indigo);
    });

    test('refunded returns orange color', () {
      final style = OrderStatusLocalization.styleForRaw('refunded');
      expect(style.label, 'İade Edildi');
      expect(style.color, Colors.orange);
    });

    test('canceled returns red color', () {
      final style = OrderStatusLocalization.styleForRaw('canceled');
      expect(style.label, 'İptal Edildi');
      expect(style.color, Colors.red);
    });

    test('unknown status returns blueGrey fallback', () {
      final style = OrderStatusLocalization.styleForRaw('mystery_status');
      expect(style.label, 'mystery_status');
      expect(style.color, Colors.blueGrey);
    });
  });

  group('PUT method - buildOrderStatusUpdateBody body values', () {
    // Ensure the body values fed to PUT are correct.
    // The actual HTTP verb change is a data-layer concern; here we verify
    // that the expected body strings align with what the API expects for PUT.
    test('store pickup body contains being_prepared (toplama tamamlandi)', () {
      // Toplama tamamlandığında mağaza teslim siparişlerde de statu
      // "Hazırlanıyor" (being_prepared) olur. Musteriye fiilen teslim
      // ayri "Teslim Et" aksiyonu ile yapilir.
      final body = buildOrderStatusUpdateBody('magazadan teslim');
      expect(body['status'], 'being_prepared');
    });

    test('cargo body contains being_prepared', () {
      final body = buildOrderStatusUpdateBody('kargo');
      expect(body['status'], 'being_prepared');
    });

    test('explicit delivered target always sends delivered', () {
      final body = buildOrderStatusUpdateBody(
        'kargo',
        target: OrderStatusTarget.delivered,
      );
      expect(body['status'], 'delivered');
    });

    test('delivered maps back to Teslim Edildi via mapper', () {
      // Round-trip: PUT body value -> UI label
      expect(OrderStatusLocalization.toTurkish('delivered'), 'Teslim Edildi');
    });

    test('being_prepared maps back to Hazırlanıyor via mapper', () {
      expect(
        OrderStatusLocalization.toTurkish('being_prepared'),
        'Hazırlanıyor',
      );
    });
  });
}
