import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants.dart';
import '../../../../services/ApiService.dart';

class VnPayWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const VnPayWebViewScreen({
    super.key,
    required this.paymentUrl,
  });

  @override
  State<VnPayWebViewScreen> createState() => _VnPayWebViewScreenState();
}

class _VnPayWebViewScreenState extends State<VnPayWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: (request) async {
            final url = request.url.toLowerCase();
            final uri = Uri.tryParse(request.url);
            final responseCode = uri?.queryParameters['vnp_ResponseCode'];
            final transactionStatus = uri?.queryParameters['vnp_TransactionStatus'];
            final isVnPayReturn = url.contains('vnpay-callback') ||
                url.contains('vnpay_return') ||
                url.contains('vnp-response') ||
                uri?.queryParameters.containsKey('vnp_ResponseCode') == true;

            // Intercept callback before WebView tries loading localhost callback URL.
            if (isVnPayReturn) {
              final success =
                  responseCode == '00' && (transactionStatus == null || transactionStatus == '00');
              await _confirmVnPayCallbackWithBackend(uri);
              if (mounted) {
                Navigator.of(context).pop(success);
              }
              return NavigationDecision.prevent;
            }

            // Prevent "ERR_CONNECTION_REFUSED" with localhost callback on emulator/device.
            if (uri != null && uri.host == 'localhost') {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
            tooltip: 'Đóng',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress < 100
              ? LinearProgressIndicator(value: _progress / 100)
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  Future<void> _confirmVnPayCallbackWithBackend(Uri? callbackUri) async {
    if (callbackUri == null || callbackUri.queryParameters.isEmpty) return;

    final endpoint = Uri.parse('${Constant().baseUrl}/payment/vnpay-client-callback');
    try {
      await http.post(
        endpoint,
        headers: await ApiService().getHeaders(),
        body: jsonEncode(callbackUri.queryParameters),
      );
    } catch (_) {
      // Keep UX smooth; backend callback may still be processed by server-side IPN.
    }
  }
}
