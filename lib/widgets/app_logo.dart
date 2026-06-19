import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    Key? key,
    this.size = 32,
    this.showText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.08), // Proportional padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28), // Squircle shape
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7B2CBF), // Cosmic Purple
                Color(0xFF3C096C), // Deep Indigo
                Color(0xFFE0AAFF), // Vibrant Magenta Glow
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2CBF).withValues(alpha: 0.35), // Updated to avoid deprecation warning
                blurRadius: size * 0.25, // Proportional blur
                spreadRadius: size * 0.05, // Proportional spread
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151026) : const Color(0xFFFCF9F2),
              borderRadius: BorderRadius.circular(size * 0.20), // Adjusted inner radius matching outer border
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cosmic Shield outline
                Icon(
                  Icons.shield_outlined,
                  color: isDark ? const Color(0xFFE0AAFF) : const Color(0xFF5A189A),
                  size: size * 0.58,
                ),
                // Gold Lightning bolt inside the shield - aligned slightly higher for optical centering
                Align(
                  alignment: const Alignment(0.0, -0.06),
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: const Color(0xFFFF9E00),
                    size: size * 0.28,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'Safenet AI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}
