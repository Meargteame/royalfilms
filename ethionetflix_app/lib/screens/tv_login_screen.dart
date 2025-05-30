// lib/screens/tv_login_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class TvLoginScreen extends StatefulWidget {
  const TvLoginScreen({Key? key}) : super(key: key);

  @override
  State<TvLoginScreen> createState() => _TvLoginScreenState();
}

class _TvLoginScreenState extends State<TvLoginScreen> {
  String? _generatedCode;
  bool _isGenerating = false;

  void _generateCode() {
    setState(() {
      _isGenerating = true;
    });
    
    // Simulate code generation with a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          // Generate a random 4-digit code (in real app, this would come from an API)
          _generatedCode = '${1000 + DateTime.now().millisecond % 9000}';
          _isGenerating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Code display
            if (_generatedCode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _generatedCode!.split('').map((digit) {
                    return Container(
                      width: 50,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        digit,
                        style: const TextStyle(
                          color: AppTheme.textColorPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 50,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            
            const SizedBox(height: 48),
            
            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.buttonTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                  disabledForegroundColor: AppTheme.buttonTextColor.withOpacity(0.5),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.buttonTextColor,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Generate',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            if (_generatedCode != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Enter this code on your TV device to link your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColorSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Code expires in 15 minutes',
                style: TextStyle(
                  color: AppTheme.textColorTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
