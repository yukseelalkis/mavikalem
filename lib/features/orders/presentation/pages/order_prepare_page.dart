import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/orders/presentation/providers/orders_providers.dart';

final class OrderPreparePage extends ConsumerWidget {
  const OrderPreparePage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderPrepareProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Siparis Hazirlama #$orderId')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Siparis detayi yuklenemedi: $error'),
          ),
        ),
        data: (order) {
          if (order.items.isEmpty) {
            return const Center(child: Text('Siparis urunu bulunamadi.'));
          }
          return ListView.separated(
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final item = order.items[index];
              final quantityText = item.quantity % 1 == 0
                  ? item.quantity.toInt().toString()
                  : item.quantity.toStringAsFixed(2);

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
                title: Text(item.name),
                subtitle: Text(
                  'Adet: $quantityText • Fiyat: ${item.unitPrice.toStringAsFixed(2)} TL',
                ),
                trailing: Text(
                  item.stockCode,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
