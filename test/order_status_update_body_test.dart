import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:mavikalem_app/features/orders/domain/order_status_target.dart';

void main() {
  group('buildOrderStatusUpdateBody (auto target)', () {
    test('returns being_prepared for store pickup (toplama tamamlandi)', () {
      final body = buildOrderStatusUpdateBody('magazadan teslim');
      expect(body, const <String, String>{'status': 'being_prepared'});
    });

    test('returns being_prepared for alternative store pickup keywords', () {
      expect(
        buildOrderStatusUpdateBody('store pickup'),
        const <String, String>{'status': 'being_prepared'},
      );
      expect(
        buildOrderStatusUpdateBody('store_pickup'),
        const <String, String>{'status': 'being_prepared'},
      );
    });

    test('returns being_prepared for cargo', () {
      final body = buildOrderStatusUpdateBody('kargo');
      expect(body, const <String, String>{'status': 'being_prepared'});
    });

    test('returns being_prepared for english cargo keywords', () {
      expect(
        buildOrderStatusUpdateBody('cargo'),
        const <String, String>{'status': 'being_prepared'},
      );
      expect(
        buildOrderStatusUpdateBody('shipping'),
        const <String, String>{'status': 'being_prepared'},
      );
    });

    test('throws for unknown delivery type', () {
      expect(
        () => buildOrderStatusUpdateBody(''),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('buildOrderStatusUpdateBody (delivered target)', () {
    test('returns delivered regardless of cargo delivery type', () {
      final body = buildOrderStatusUpdateBody(
        'kargo',
        target: OrderStatusTarget.delivered,
      );
      expect(body, const <String, String>{'status': 'delivered'});
    });

    test('returns delivered regardless of store pickup delivery type', () {
      final body = buildOrderStatusUpdateBody(
        'magazadan teslim',
        target: OrderStatusTarget.delivered,
      );
      expect(body, const <String, String>{'status': 'delivered'});
    });

    test('returns delivered even when delivery type is unknown/null', () {
      expect(
        buildOrderStatusUpdateBody(null, target: OrderStatusTarget.delivered),
        const <String, String>{'status': 'delivered'},
      );
      expect(
        buildOrderStatusUpdateBody('', target: OrderStatusTarget.delivered),
        const <String, String>{'status': 'delivered'},
      );
      expect(
        buildOrderStatusUpdateBody(
          'unknown-tip',
          target: OrderStatusTarget.delivered,
        ),
        const <String, String>{'status': 'delivered'},
      );
    });
  });
}
