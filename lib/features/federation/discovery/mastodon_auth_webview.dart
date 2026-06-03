import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Full-screen in-app WebView for the Mastodon OAuth flow.
///
/// Push this route with [Navigator.push] and await the result — it returns
/// the full callback URL string on success, or null if the user cancels.
class MastodonAuthWebView extends StatefulWidget {
  const MastodonAuthWebView({
    super.key,
    required this.authUrl,
    required this.callbackScheme,
  });

  final String authUrl;
  final String callbackScheme;

  /// Convenience method: pushes the webview and returns the callback URL.
  static Future<String?> show(
    BuildContext context, {
    required String authUrl,
    required String callbackScheme,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MastodonAuthWebView(
          authUrl: authUrl,
          callbackScheme: callbackScheme,
        ),
      ),
    );
  }

  @override
  State<MastodonAuthWebView> createState() => _MastodonAuthWebViewState();
}

class _MastodonAuthWebViewState extends State<MastodonAuthWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            if (request.url.startsWith('${widget.callbackScheme}://')) {
              Navigator.of(context).pop(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Mastodon'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
