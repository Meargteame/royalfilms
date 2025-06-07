import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import '../services/chapa_service.dart';
import '../services/chapa_proxy.dart';
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
  bool _isWebEnvironment = kIsWeb;
  
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
    print('Running in web environment: $_isWebEnvironment');
    
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
        print('Received checkout URL: $checkoutUrl');
        
        setState(() {
          _paymentUrl = checkoutUrl;
          _initializeWebView(checkoutUrl);
        });
      } else {
        _showError('Payment initialization failed: ${response['message'] ?? "Unknown error"}');
        widget.onPaymentComplete(false);
      }
    } catch (e) {
      print('Payment error caught: $e');
      String errorMessage;
      
      if (_isWebEnvironment && e.toString().contains('Failed to fetch')) {
        errorMessage = 'Unable to connect to payment gateway directly from web browser.\n\n'
                      'This is typically due to CORS restrictions in web browsers.\n\n'
                      'In a production app, this would be handled via a server-side proxy or by using Chapa\'s hosted checkout page.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        errorMessage = 'Could not connect to the payment server. Please check your internet connection and try again.';
      } else {
        errorMessage = e.toString();
      }
      
      _showError(errorMessage);
      widget.onPaymentComplete(false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add a simulation method for web testing
  void _simulatePaymentForWebTesting() {
    // This is only for demo purposes in web preview
    if (!_isWebEnvironment) return;
    
    setState(() => _isLoading = true);
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulating payment process for web demo...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      )
    );
    
    // Simulate a delay and successful payment
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment simulation successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          )
        );
        
        setState(() => _isLoading = false);
        widget.onPaymentComplete(true);
        
        // Return to previous screen after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  void _showError(String message) {
    print('Payment error: $message');
    if (!mounted) return;
    
    // For web environment with CORS errors, show a dialog with more details
    if (_isWebEnvironment && (message.contains('CORS') || message.contains('Failed to fetch'))) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Web Browser Limitation'),
          content: const Text(
            'Payment gateway cannot be accessed directly from the browser due to security restrictions.\n\n'
            'In production, this would be handled with a proper backend.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializePayment();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
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
              
              // Add a web testing button
              if (_isWebEnvironment)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _simulatePaymentForWebTesting,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    child: const Text('Simulate Successful Payment (Web Demo)'),
                  ),
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