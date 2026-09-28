import 'package:flutter/material.dart';

class CustomerResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const CustomerResponsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1100;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  static double contentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1400) return 1240;
    if (width >= 1100) return 1080;
    if (width >= 600) return 760;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (width >= 600) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class CustomerPage extends StatelessWidget {
  final Widget child;

  const CustomerPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: CustomerResponsive.contentWidth(context),
        ),
        child: child,
      ),
    );
  }
}
