// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(width: 150, height: 48),
                const SizedBox(height: 32),
                
                if (!_emailSent) ...[
                  const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email and we\'ll send you a link to reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Your email',
                      hintStyle: TextStyle(color: AppTheme.textColorTertiary),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppTheme.textColorSecondary,
                      ),
                    ),
                    style: const TextStyle(color: AppTheme.textColorPrimary),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Send Reset Link button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                        disabledForegroundColor: AppTheme.buttonTextColor.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppTheme.buttonTextColor,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send Reset Link',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ] else ...[
                  // Success message when email is sent
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.successColor,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Reset Link Sent!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'ve sent a password reset link to ${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your email and follow the instructions to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Return to login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Return to Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Didn't receive link button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                      });
                    },
                    child: const Text(
                      'Didn\'t receive the link? Try again',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
