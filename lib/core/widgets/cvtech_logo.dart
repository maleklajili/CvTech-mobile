import 'package:flutter/material.dart';

/// CvTech logo widget — displays the app logo from assets.
/// Supports custom size and optional text display below.
class CvTechLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const CvTechLogo({super.key, this.size = 120, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.18),
          child: Image.asset(
            'assets/logo/cvtech_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback: colored box with text if image not found
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00BCD4), Color(0xFF9C27B0), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(size * 0.18),
                ),
                child: Center(
                  child: Text(
                    'CV',
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.12),
          Text(
            'CvTech',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6C63FF),
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
