import 'package:flutter/material.dart';

/// Central brand palette for AutoPost AI.
///
/// Derived from the app logo (`assets/splash.png`): a deep purple field,
/// a white woven knot, and a pink → magenta gradient ribbon.
///
/// Use these constants instead of ad-hoc `Color(0x...)` / `Colors.blue`
/// literals so every screen stays visually consistent.
class AppColors {
  AppColors._();

  /// Primary brand colour — the deep purple from the logo background.
  static const Color primary = Color(0xFF572D74);

  /// Secondary accent — the magenta end of the logo ribbon.
  static const Color accent = Color(0xFFE0185F);

  /// Lighter coral-pink — the start of the logo ribbon.
  static const Color accentLight = Color(0xFFF65B7E);

  /// Standard brand gradient (purple → magenta) used for logos, headers
  /// and primary call-to-action surfaces.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic colours (kept conventional, brand-independent).
  static const Color success = Color(0xFF2E9E5B);
  static const Color error = Color(0xFFD93025);
}

/// Reusable brand logo mark.
///
/// Renders the actual app logo (`assets/splash.png`) inside a rounded square
/// so every screen header shows the same mark at a consistent size.
class AppLogo extends StatelessWidget {
  final double size;
  final double radius;

  const AppLogo({super.key, this.size = 50, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/splash.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
