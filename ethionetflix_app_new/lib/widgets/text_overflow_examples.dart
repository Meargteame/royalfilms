// lib/widgets/text_overflow_examples.dart
// This file demonstrates different text overflow handling approaches

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Example widget showing different text overflow handling strategies
class TextOverflowExamples extends StatelessWidget {
  final String sampleLongTitle = "HOW TO TRAIN YOUR DRAGON 2025 አንድራጎን በማሰልጠን መንገድ ሙሉ ፊልም";
  
  const TextOverflowExamples({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Text Overflow Examples'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Single Line with Ellipsis',
              _buildSingleLineExample(),
              'Best for: Horizontal lists, compact layouts',
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Two Lines with Ellipsis',
              _buildTwoLineExample(),
              'Best for: Grid layouts, detailed cards',
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Fade Out Effect',
              _buildFadeOutExample(),
              'Best for: Modern Netflix-style cards',
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Auto-sizing Text',
              _buildAutoSizeExample(),
              'Best for: Variable container sizes',
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Fixed Height Container',
              _buildFixedHeightExample(),
              'Best for: Consistent card dimensions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget example, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textColorPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: AppTheme.textColorSecondary,
            fontSize: 14,
            fontFamily: AppTheme.secondaryFontFamily,
          ),
        ),
        const SizedBox(height: 16),
        example,
      ],
    );
  }

  /// Single line text with ellipsis - most efficient
  Widget _buildSingleLineExample() {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.movieCardDecoration,
      child: Text(
        sampleLongTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.textColorPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
    );
  }

  /// Two lines with ellipsis - good balance
  Widget _buildTwoLineExample() {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.movieCardDecoration,
      child: Text(
        sampleLongTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.textColorPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.2,
          fontFamily: AppTheme.primaryFontFamily,
        ),
      ),
    );
  }

  /// Fade out effect using ShaderMask
  Widget _buildFadeOutExample() {
    return Container(
      width: 150,
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.movieCardDecoration,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.7, 1.0],
        ).createShader(bounds),
        child: Text(
          sampleLongTitle,
          style: const TextStyle(
            color: AppTheme.textColorPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            fontFamily: AppTheme.primaryFontFamily,
          ),
        ),
      ),
    );
  }

  /// Auto-sizing text that scales to fit
  Widget _buildAutoSizeExample() {
    return Container(
      width: 150,
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.movieCardDecoration,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate font size based on text length and available space
          double fontSize = 14.0;
          if (sampleLongTitle.length > 30) fontSize = 12.0;
          if (sampleLongTitle.length > 50) fontSize = 10.0;
          
          return Text(
            sampleLongTitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textColorPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.1,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          );
        },
      ),
    );
  }

  /// Fixed height container with overflow handling
  Widget _buildFixedHeightExample() {
    return Container(
      width: 150,
      height: 80, // Fixed height
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.movieCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              sampleLongTitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textColorPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.1,
                fontFamily: AppTheme.primaryFontFamily,
              ),
            ),
          ),
          // Always keep this at bottom
          Text(
            '2025 • Movie',
            style: const TextStyle(
              color: AppTheme.textColorSecondary,
              fontSize: 10,
              fontFamily: AppTheme.secondaryFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

/// Utility class for text overflow handling
class TextOverflowUtils {
  /// Truncate text intelligently at word boundaries
  static String truncateAtWord(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    
    int lastSpace = text.lastIndexOf(' ', maxLength);
    if (lastSpace > 0 && lastSpace > maxLength * 0.7) {
      return '${text.substring(0, lastSpace)}...';
    }
    
    return '${text.substring(0, maxLength)}...';
  }

  /// Calculate optimal font size for given constraints
  static double calculateOptimalFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
    required int maxLines,
    double baseFontSize = 14.0,
  }) {
    // Simple heuristic - adjust based on text length
    double fontSize = baseFontSize;
    int textLength = text.length;
    
    if (textLength > 20) fontSize -= 1;
    if (textLength > 40) fontSize -= 1;
    if (textLength > 60) fontSize -= 1;
    
    return fontSize.clamp(8.0, baseFontSize);
  }

  /// Check if text will overflow with given constraints
  static bool willTextOverflow({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }
}

/// Custom widget for smart text rendering
class SmartText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final TextOverflow overflow;
  final double? maxWidth;
  final bool adaptiveFontSize;

  const SmartText(
    this.text, {
    Key? key,
    required this.style,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.maxWidth,
    this.adaptiveFontSize = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle effectiveStyle = style;
    
    if (adaptiveFontSize && maxWidth != null) {
      double optimalFontSize = TextOverflowUtils.calculateOptimalFontSize(
        text: text,
        maxWidth: maxWidth!,
        maxHeight: (style.fontSize ?? 14) * maxLines * (style.height ?? 1.2),
        maxLines: maxLines,
        baseFontSize: style.fontSize ?? 14,
      );
      
      effectiveStyle = style.copyWith(fontSize: optimalFontSize);
    }

    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      style: effectiveStyle,
    );
  }
}
