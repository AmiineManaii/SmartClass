import 'package:flutter/material.dart';

/// Breakpoints standardisés pour l'adaptation Web / Tablette / Mobile.
class AppBreakpoints {
  static const double mobileMax = 767.0;
  static const double tabletMin = 768.0;
  static const double tabletMax = 1023.0;
  static const double desktopMin = 1024.0;
  static const double desktopWide = 1440.0;
}

/// Widget générique adaptatif commutant entre les vues Mobile, Tablette et Desktop.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Méthode d'aide statique pour savoir si le viewport actuel est desktop.
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.desktopMin;
  }

  /// Méthode d'aide statique pour savoir si le viewport actuel est tablette.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppBreakpoints.tabletMin && width < AppBreakpoints.desktopMin;
  }

  /// Méthode d'aide statique pour savoir si le viewport actuel est mobile.
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.tabletMin;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktopMin) {
          return desktop;
        } else if (constraints.maxWidth >= AppBreakpoints.tabletMin) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
