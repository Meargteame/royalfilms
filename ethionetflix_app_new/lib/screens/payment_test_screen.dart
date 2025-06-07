import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/payment_screen.dart';

class PaymentTestScreen extends StatelessWidget {
  const PaymentTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapa Payment Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This is a test page for Chapa payment integration',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      amount: 99.99,
                      movieTitle: 'Test Payment',
                      onPaymentComplete: (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Payment successful!'
                                  : 'Payment failed or cancelled',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: const Text('Test Chapa Payment (99.99 ETB)'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Note: This will use the Chapa test environment',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
