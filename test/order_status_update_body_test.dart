import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/features/orders/data/datasources/orders_remote_datasource.dart';

void main() {
  group('buildOrderStatusUpdateBody', () {
    test('returns being_prepared for store pickup (toplama tamamlandi)', () {
      final body = buildOrderStatusUpdateBody('magazadan teslim');
      expect(body, const <String, String>{'status': 'being_prepared'});
    });

    test('returns being_prepared for cargo', () {
      final body = buildOrderStatusUpdateBody('kargo');
      expect(body, const <String, String>{'status': 'being_prepared'});
    });

    test('throws for unknown delivery type', () {
      expect(
        () => buildOrderStatusUpdateBody(''),
        throwsA(isA<StateError>()),
      );
    });
  });
}
