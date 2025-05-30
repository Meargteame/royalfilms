// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
              
              const SizedBox(height: 24),
              
              // Logo
              Center(
                child: Column(
                  children: [
                    const AppLogo(width: 150, height: 48),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hello there, Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Email field
              TextField(
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
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextField(
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
              ),
              
              const SizedBox(height: 8),
              
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to forgot password screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textColorSecondary,
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle login
                    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                      // Navigate to home screen after successful login
                      Navigator.pop(context, true);
                    } else {
                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter both email and password'),
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
                    'Login now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Divider with text
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppTheme.textColorTertiary),
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
                    child: Divider(color: AppTheme.textColorTertiary),
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
              
              // Sign up text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Haven't signed up yet?",
                    style: TextStyle(
                      color: AppTheme.textColorSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to sign up screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      'Create account',
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
    );
  }
}
