import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/chapa_service.dart';
import '../config/chapa_config.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String movieTitle;
  final Function(bool success) onPaymentComplete;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.movieTitle,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapaService = ChapaService();
  bool _isLoading = false;
  String? _paymentUrl;
  WebViewController? _webViewController;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  void _initializeWebView(String url) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,
          onPageStarted: (String url) {
            print('Payment page loading: $url');
          },
          onPageFinished: (String url) {
            print('Payment page loaded: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('Payment page error: ${error.description}');
            _showError('Payment error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    print('WebView navigating to: ${request.url}');
    
    if (request.url.startsWith('https://ethionetflix.com/payment/success')) {
      print('Payment successful, closing payment screen');
      widget.onPaymentComplete(true);
      Navigator.of(context).pop();
      return NavigationDecision.prevent;
    }
    if (request.url.startsWith('https://ethionetflix.com/payment/cancel') ||
        request.url.contains('cancel') ||
        request.url.contains('failed')) {
      print('Payment cancelled or failed');
      widget.onPaymentComplete(false);
      Navigator.of(context).pop();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  String _generateTxRef() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final result = List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
    return 'tx-$result';
  }

  Future<void> _initializePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _showLoading('Initializing payment...');

    final txRef = _generateTxRef();
    print('Generated transaction reference: $txRef');
    print('Initializing payment for amount: ${widget.amount} ETB');
    
    // Clear any existing error messages
    ScaffoldMessenger.of(context).clearSnackBars();

    try {
      print('Starting payment initialization...');
      final response = await _chapaService.initializePayment(
        amount: widget.amount.toString(),
        currency: ChapaConfig.currency,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        txRef: txRef,
        returnUrl: 'https://ethionetflix.com/payment/success',
        callbackUrl: 'https://ethionetflix.com/payment/callback',
      );
      
      print('Payment initialization response: $response');

      if (response['status'] == 'success') {
        final checkoutUrl = response['data']['checkout_url'];
        setState(() {
          _paymentUrl = checkoutUrl;
          _initializeWebView(checkoutUrl);
        });
      } else {
        _showError('Payment initialization failed');
        widget.onPaymentComplete(false);
      }
    } catch (e) {
      _showError(e.toString());
      widget.onPaymentComplete(false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    print('Payment error: $message');
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _initializePayment,
        ),
      ),
    );
  }

  void _showLoading(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentUrl != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.onPaymentComplete(false);
              Navigator.of(context).pop();
            },
          ),
        ),
        body: _webViewController != null
            ? WebViewWidget(controller: _webViewController!)
            : const Center(
                child: CircularProgressIndicator(),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Payment for ${widget.movieTitle}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ${widget.amount} ETB',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _initializePayment,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Proceed to Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
} 