// lib/widgets/logo.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final double height;

  const AppLogo({Key? key, this.width = 120, this.height = 36})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.movie_outlined,
          color: AppTheme.primaryColor,
          size: height * 0.8,
        ),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Royal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: height * 0.5,
                ),
              ),
              TextSpan(
                text: 'Films',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: height * 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
