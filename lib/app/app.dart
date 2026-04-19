import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:mavikalem_app/features/auth/presentation/pages/auth_page.dart';
import 'package:mavikalem_app/features/orders/presentation/pages/orders_page.dart';
import 'package:mavikalem_app/features/product_check/presentation/pages/product_check_page.dart';
import 'package:mavikalem_app/shared/presentation/theme/app_theme.dart';

final class WarehouseApp extends ConsumerWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStatusProvider);

    return MaterialApp(
      title: 'Mavi Kalem Depo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: authState.when(
        data: (isAuthenticated) =>
            isAuthenticated ? const _HomeNavigationShell() : const AuthPage(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Oturum durumu okunamadi: $error'),
            ),
          ),
        ),
      ),
    );
  }
}

final class _HomeNavigationShell extends StatefulWidget {
  const _HomeNavigationShell();

  @override
  State<_HomeNavigationShell> createState() => _HomeNavigationShellState();
}

final class _HomeNavigationShellState extends State<_HomeNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [OrdersPage(), ProductCheckPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Siparisler',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Urun Kontrol',
          ),
        ],
      ),
    );
  }
}
