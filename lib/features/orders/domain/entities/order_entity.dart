import 'package:mavikalem_app/features/orders/domain/entities/order_item_entity.dart';
import 'package:mavikalem_app/features/orders/domain/entities/shipping_address_entity.dart';

class OrderEntity {
  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.createdAt,
    required this.items,
    this.shippingAddress,
    this.finalAmount,
    this.paymentTypeName,
    this.deliveryTypeRaw,
  });

  final int id;
  final String orderNumber;
  final String customerName;
  final String status;
  final DateTime? createdAt;
  final List<OrderItemEntity> items;

  final ShippingAddressEntity? shippingAddress;
  final double? finalAmount;
  final String? paymentTypeName;
  final String? deliveryTypeRaw;
}
