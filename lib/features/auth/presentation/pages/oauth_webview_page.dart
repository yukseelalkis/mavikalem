import 'package:flutter/material.dart';
import 'package:mavikalem_app/core/constants/oauth_config.dart';
import 'package:webview_flutter/webview_flutter.dart';

final class OAuthWebViewPage extends StatefulWidget {
  const OAuthWebViewPage({required this.initialUrl, super.key});

  final Uri initialUrl;

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

final class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  bool _pageLoading = true;
  bool _intercepting = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _pageLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _pageLoading = false);
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(OAuthConfig.redirectUriPrefix)) {
              if (!_intercepting && mounted) {
                _intercepting = true;
                Navigator.of(context).pop(Uri.parse(url));
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(widget.initialUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IdeaSoft Giris')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_pageLoading || _intercepting)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
