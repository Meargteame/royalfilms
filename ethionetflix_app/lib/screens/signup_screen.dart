// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Logo
                Center(
                  child: Column(
                    children: [
                      const AppLogo(width: 150, height: 48),
                      const SizedBox(height: 24),
                      const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to continue to EthioNetflix',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: AppTheme.textColorTertiary),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.textColorPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
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
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: AppTheme.textColorTertiary),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.textColorSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textColorSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.textColorPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(color: AppTheme.textColorTertiary),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.textColorSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textColorSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.textColorPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Terms and conditions checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                      checkColor: AppTheme.buttonTextColor,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 14),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Signup button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _acceptTerms) {
                        // Handle signup
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account created successfully'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        Navigator.pop(context);
                      } else if (!_acceptTerms) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please agree to the Terms and Conditions'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider with text
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppTheme.dividerColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppTheme.textColorTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppTheme.dividerColor),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Google sign in button
                OutlinedButton.icon(
                  onPressed: () {
                    // Handle Google sign in
                  },
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textColorPrimary,
                    side: BorderSide(color: AppTheme.textColorTertiary),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: AppTheme.textColorSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
