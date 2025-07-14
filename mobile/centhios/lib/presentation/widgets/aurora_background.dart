import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app_theme.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(1.5, -1.2),
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-1.5, 0.7),
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
