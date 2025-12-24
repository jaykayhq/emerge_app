import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AvatarCreatorWebView extends StatefulWidget {
  const AvatarCreatorWebView({super.key});

  @override
  State<AvatarCreatorWebView> createState() => _AvatarCreatorWebViewState();
}

class _AvatarCreatorWebViewState extends State<AvatarCreatorWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Inject the bridge script when page finishes loading
            _controller.runJavaScript('''
              window.addEventListener('message', function(event) {
                  if (event.data) {
                       var data = event.data;
                       if (typeof data === 'object') {
                           data = JSON.stringify(data);
                       }
                       window.ReadyPlayerMe.postMessage(data);
                  }
              });
            ''');
          },
        ),
      )
      ..addJavaScriptChannel(
        'ReadyPlayerMe',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            // Check for the exported event
            // The data structure might be slightly different depending on the version
            // Usually: { "eventName": "v1.avatar.exported", "data": { "url": "..." } }
            // Or sometimes type: 'v1.avatar.exported'

            final eventName = data['eventName'] ?? data['type'];

            if (eventName == 'v1.avatar.exported') {
              final url = data['data']?['url'];
              if (url != null) {
                if (mounted) {
                  Navigator.of(context).pop(url);
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        },
      )
      ..loadRequest(
        Uri.parse('https://emerge-gq7t9u.readyplayer.me/avatar?frameApi'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      appBar: AppBar(
        title: Text(
          'Create Avatar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textMainDark),
          onPressed: () => Navigator.of(context).pop(), // Return null on cancel
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
