import 'package:flutter/material.dart';

class CustomerTheme {
  // Primary brand orange and accents from reference UI
  static const Color primary = Color(0xFFF45B15);
  static const Color primaryLight = Color(0xFFFFF2EB);
  static const Color primaryDark = Color(0xFFD64A0B);

  // Backgrounds
  static const Color scaffoldBg = Color(0xFFF9F9FB);
  static const Color cardBg = Colors.white;
  static const Color borderSubtle = Color(0xFFECECEC);

  // Text colors
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMuted = Color(0xFF75787E);
  static const Color textLight = Color(0xFF9EA1A8);

  // Status colors
  static const Color greenSuccess = Color(0xFF10B981);
  static const Color greenLight = Color(0xFFE8F8F2);
  static const Color redDanger = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFEECEC);
  static const Color amberWarning = Color(0xFFF59E0B);

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: Color(0x40F45B15),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // Helper container for responsive screens: centers and max-widths gracefully
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    double maxWidth = 560,
    EdgeInsetsGeometry? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: child,
        ),
      ),
    );
  }
}
