import 'package:flutter_test/flutter_test.dart';
import 'package:mavikalem_app/core/delivery/delivery_type_kind.dart';

void main() {
  group('resolveDeliveryType', () {
    test('returns unknown for null and empty values', () {
      expect(resolveDeliveryType(null), DeliveryTypeKind.unknown);
      expect(resolveDeliveryType('   '), DeliveryTypeKind.unknown);
    });

    test('detects store pickup values case-insensitively', () {
      expect(resolveDeliveryType('PICKUP'), DeliveryTypeKind.storePickup);
      expect(resolveDeliveryType('magaza'), DeliveryTypeKind.storePickup);
      expect(
        resolveDeliveryType('Store pickup available'),
        DeliveryTypeKind.storePickup,
      );
    });

    test('detects cargo values case-insensitively', () {
      expect(resolveDeliveryType('KARGO'), DeliveryTypeKind.cargo);
      expect(resolveDeliveryType('shipping'), DeliveryTypeKind.cargo);
      expect(resolveDeliveryType('Cargo delivery'), DeliveryTypeKind.cargo);
    });

    test('returns unknown for unsupported values', () {
      expect(resolveDeliveryType('digital'), DeliveryTypeKind.unknown);
    });
  });
}
