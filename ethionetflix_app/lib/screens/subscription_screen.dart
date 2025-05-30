// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to Standard plan
  String _selectedPaymentMethod = 'credit_card';
  bool _processingPayment = false;
  bool _annualBilling = false;

  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'name': 'Basic',
      'price': 499,
      'features': [
        'Watch on 1 device at a time',
        'Access to limited library',
        'SD quality (480p)',
        '1 profile allowed',
        'No downloads'
      ],
      'color': Colors.grey.shade700,
    },
    {
      'name': 'Standard',
      'price': 999,
      'features': [
        'Watch on 2 devices at a time',
        'Access to full library',
        'HD quality (1080p)',
        '3 profiles allowed',
        'Downloads on 2 devices'
      ],
      'color': AppTheme.primaryColor,
      'popular': true,
    },
    {
      'name': 'Premium',
      'price': 1499,
      'features': [
        'Watch on 4 devices at a time',
        'Access to full library + exclusives',
        '4K Ultra HD + HDR',
        '5 profiles allowed',
        'Downloads on 4 devices'
      ],
      'color': Colors.redAccent,
    },
  ];

  double get _selectedPrice {
    final basePriceInBirr = _subscriptionPlans[_selectedPlanIndex]['price'];
    return _annualBilling ? basePriceInBirr * 10 : basePriceInBirr;
  }

  String get _formattedPrice {
    return '${_selectedPrice.toStringAsFixed(0)} ETB${_annualBilling ? '/year' : '/month'}';
  }

  void _processPayment() {
    setState(() {
      _processingPayment = true;
    });
    
    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _processingPayment = false;
        });
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Payment Successful', style: TextStyle(color: AppTheme.textColorPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your ${_subscriptionPlans[_selectedPlanIndex]['name']} plan subscription has been activated successfully!',
              style: const TextStyle(color: AppTheme.textColorSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Enjoy unlimited streaming of your favorite movies and series.',
              style: const TextStyle(color: AppTheme.textColorSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text(
              'Start Watching',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogo(width: 150, height: 48),
            const SizedBox(height: 24),
            
            // Billing cycle toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Billing Cycle',
                        style: TextStyle(
                          color: AppTheme.textColorPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _annualBilling 
                            ? 'Annual (Save 16%)' 
                            : 'Monthly',
                        style: TextStyle(
                          color: _annualBilling 
                              ? AppTheme.primaryColor 
                              : AppTheme.textColorSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _annualBilling,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _annualBilling = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Plan selection section
            const Text(
              'Choose a Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Subscription plans cards
            for (int i = 0; i < _subscriptionPlans.length; i++)
              _buildPlanCard(i),
            
            const SizedBox(height: 24),
            
            // Payment method section
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment method cards
            _buildPaymentMethodCard(
              'credit_card',
              'Credit/Debit Card',
              Icons.credit_card,
            ),
            _buildPaymentMethodCard(
              'telebirr',
              'TeleBirr',
              Icons.phone_android,
            ),
            _buildPaymentMethodCard(
              'chapa',
              'Chapa Payment',
              Icons.payment,
            ),
            
            const SizedBox(height: 32),
            
            // Payment summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    'Plan',
                    _subscriptionPlans[_selectedPlanIndex]['name'],
                  ),
                  _buildSummaryRow(
                    'Billing',
                    _annualBilling ? 'Annual' : 'Monthly',
                  ),
                  _buildSummaryRow(
                    'Payment Method',
                    _selectedPaymentMethod == 'credit_card'
                        ? 'Credit/Debit Card'
                        : _selectedPaymentMethod == 'telebirr'
                            ? 'TeleBirr'
                            : 'Chapa Payment',
                  ),
                  const Divider(color: AppTheme.dividerColor),
                  _buildSummaryRow(
                    'Total',
                    _formattedPrice,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processingPayment ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.buttonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                  disabledForegroundColor: AppTheme.buttonTextColor.withOpacity(0.5),
                ),
                child: _processingPayment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.buttonTextColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Subscribe for $_formattedPrice',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Terms and conditions note
            Center(
              child: Text(
                'By subscribing, you agree to our Terms & Conditions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColorTertiary,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final plan = _subscriptionPlans[index];
    final isSelected = _selectedPlanIndex == index;
    final isPremium = plan['name'] == 'Premium';
    final isPopular = plan.containsKey('popular') && plan['popular'] == true;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? plan['color'] : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: plan['color'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.buttonTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan['name'],
                        style: TextStyle(
                          color: plan['color'],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: plan['color'],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${plan['price']} ETB',
                          style: const TextStyle(
                            color: AppTheme.textColorPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: _annualBilling ? '/year' : '/month',
                          style: const TextStyle(
                            color: AppTheme.textColorSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final feature in plan['features'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: plan['color'],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: AppTheme.textColorSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textColorSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textColorPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.textColorPrimary : AppTheme.textColorSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppTheme.primaryColor : AppTheme.textColorPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
