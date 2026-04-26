import 'package:mavikalem_app/features/picking/domain/entities/picked_item.dart';

final class PickedItemModel extends PickedItem {
  const PickedItemModel({
    required super.id,
    required super.orderId,
    required super.sku,
    required super.productName,
    required super.quantity,
    required super.updatedAt,
  });

  factory PickedItemModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic raw) {
      final text = raw?.toString().trim() ?? '';
      final parsed = DateTime.tryParse(text);
      if (parsed == null) {
        throw StateError('Invalid picked_items timestamp: $raw');
      }
      return parsed.toLocal();
    }

    return PickedItemModel(
      id: (map['id'] ?? '').toString(),
      orderId: (map['order_id'] as num?)?.toInt() ?? 0,
      sku: (map['sku'] ?? '').toString(),
      productName: (map['product_name'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      'order_id': orderId,
      'sku': sku,
      'product_name': productName,
      'quantity': quantity,
    };
  }
}
