import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/paystack_payment_repository.dart';

/// Identity-First Paystack Checkout Screen
///
/// Uses `flutter_inappwebview` to present the Paystack Standard Checkout,
/// which supports Apple Pay (on Safari) and Google Pay natively.
class PaystackCheckoutScreen extends ConsumerStatefulWidget {
  final double amount;
  final String email;
  final String identityType;

  const PaystackCheckoutScreen({
    super.key,
    required this.amount,
    required this.email,
    required this.identityType,
  });

  @override
  ConsumerState<PaystackCheckoutScreen> createState() =>
      _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState
    extends ConsumerState<PaystackCheckoutScreen> {
  String? _authorizationUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeTransaction();
  }

  Future<void> _initializeTransaction() async {
    try {
      final repository = ref.read(paystackPaymentRepositoryProvider);
      final url = await repository.initializeTransaction(
        amount: widget.amount,
        email: widget.email,
        identityType: widget.identityType,
      );

      if (mounted) {
        setState(() {
          _authorizationUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to initialize payment. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Identity-first minimalism: dark background, elegant loading states.
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Cosmic Void Dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(false),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blueAccent, // Use your theme color here
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeTransaction();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_authorizationUrl != null) {
      return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_authorizationUrl!)),
        onLoadStart: (controller, url) {
          // You can handle success redirects here if you configure a callback URL in Paystack
          // Alternatively, rely entirely on webhooks in Firebase Functions.
          if (url != null &&
              url.toString().contains('your-success-callback-url')) {
            context.pop(true);
          }
        },
      );
    }

    return const SizedBox.shrink();
  }
}
