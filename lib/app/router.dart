import 'package:flutter/material.dart';
import 'package:mavikalem_app/features/auth/presentation/pages/auth_page.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/order_prepare_page.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/orders_page.dart';
import 'package:mavikalem_app/features/product_check/presentation/pages/product_check_page.dart';

final class AppRoutes {
  static const String auth = '/auth';
  static const String orders = '/orders';
  static const String orderPrepare = '/orders/prepare';
  static const String productCheck = '/product-check';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.auth:
      return MaterialPageRoute<void>(
        builder: (_) => const AuthPage(),
        settings: settings,
      );
    case AppRoutes.orders:
      return MaterialPageRoute<void>(
        builder: (_) => const OrdersPage(),
        settings: settings,
      );
    case AppRoutes.productCheck:
      return MaterialPageRoute<void>(
        builder: (_) => const ProductCheckPage(),
        settings: settings,
      );
    case AppRoutes.orderPrepare:
      final args = settings.arguments;
      if (args is int) {
        return MaterialPageRoute<void>(
          builder: (_) => OrderPreparePage(orderId: args),
          settings: settings,
        );
      }
      return _errorRoute('Order id bulunamadi');
    default:
      return _errorRoute('Sayfa bulunamadi');
  }
}

MaterialPageRoute<void> _errorRoute(String message) {
  return MaterialPageRoute<void>(
    builder: (_) => Scaffold(body: Center(child: Text(message))),
  );
}
