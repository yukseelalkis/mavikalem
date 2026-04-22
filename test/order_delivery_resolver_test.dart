import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/core/delivery/delivery_type_kind.dart';

void main() {
  group('extractOrderDeliveryTypeRaw', () {
    test('returns cargo signal for Kargonomi provider code', () {
      final raw = extractOrderDeliveryTypeRaw(const {
        'shippingProviderCode': 'kargonomi',
        'shippingProviderName': 'Kargonomi',
        'shippingPaymentType': 'standart_delivery',
      });

      expect(raw, isNotNull);
      expect(resolveDeliveryType(raw), DeliveryTypeKind.cargo);
    });

    test('returns cargo signal for provider name even if code is missing', () {
      final raw = extractOrderDeliveryTypeRaw(const {
        'shippingProviderName': 'XYZ Kargo A.S.',
      });

      expect(resolveDeliveryType(raw), DeliveryTypeKind.cargo);
    });

    test('detects cargo hint from shippingPaymentType alone', () {
      final raw = extractOrderDeliveryTypeRaw(const {
        'shippingPaymentType': 'standard_shipping',
      });

      expect(resolveDeliveryType(raw), DeliveryTypeKind.cargo);
    });

    test(
      'prefers cargo provider over shipping_location_id stock reference',
      () {
        final raw = extractOrderDeliveryTypeRaw(const {
          'shippingProviderCode': 'kargonomi',
          'shippingProviderName': 'Kargonomi',
          'orderDetails': [
            {
              'id': 3,
              'varKey': 'cart_attributes',
              'varValue': '{"shipping_location_id":"1"}',
            },
          ],
        });

        expect(resolveDeliveryType(raw), DeliveryTypeKind.cargo);
      },
    );

    test(
      'falls back to store pickup when shipping_location_id exists without cargo provider',
      () {
        final raw = extractOrderDeliveryTypeRaw(const {
          'orderDetails': [
            {
              'id': 3,
              'varKey': 'cart_attributes',
              'varValue': '{"shipping_location_id":"1"}',
            },
          ],
        });

        expect(resolveDeliveryType(raw), DeliveryTypeKind.storePickup);
      },
    );

    test('returns null when order has no shipping metadata', () {
      final raw = extractOrderDeliveryTypeRaw(const {
        'id': 1,
        'customerFirstname': 'x',
      });

      expect(raw, isNull);
      expect(resolveDeliveryType(raw), DeliveryTypeKind.unknown);
    });
  });
}
