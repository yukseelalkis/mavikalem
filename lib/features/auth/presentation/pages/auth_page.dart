import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/auth/presentation/pages/oauth_webview_page.dart';
import 'package:mavikalem_app/features/auth/presentation/providers/auth_providers.dart';

final class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

final class _AuthPageState extends ConsumerState<AuthPage> {
  late final ProviderSubscription<AuthControllerState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthControllerState>(
      authControllerProvider,
      (previous, next) {
        if (next.stage == AuthFlowStage.error &&
            next.errorMessage != null &&
            mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giris basarisiz: ${next.errorMessage}')),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }

  Future<void> _startLogin() async {
    final controller = ref.read(authControllerProvider.notifier);
    final request = controller.prepareOAuthRequest();

    final redirectUri = await Navigator.of(context).push<Uri>(
      MaterialPageRoute<Uri>(
        builder: (_) => OAuthWebViewPage(initialUrl: request.url),
      ),
    );

    if (!mounted) return;
    if (redirectUri == null) {
      controller.resetIdle();
      return;
    }
    await controller.completeLoginWithRedirect(redirectUri);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open_rounded, size: 52),
                const SizedBox(height: 12),
                const Text(
                  'IdeaSoft Depo Girisi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Devam etmek icin IdeaSoft hesabinizla giris yapin.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _startLogin,
                    child: authState.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('IdeaSoft ile Giris Yap'),
                  ),
                ),
                if (authState.stage == AuthFlowStage.exchangingToken) ...[
                  const SizedBox(height: 16),
                  const Text('Token aliniyor, lutfen bekleyin...'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
