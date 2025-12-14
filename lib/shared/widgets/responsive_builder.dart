import 'package:flutter/material.dart';

/// Screen size breakpoints (mobile-first approach)
abstract class Breakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType, BoxConstraints constraints) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  static DeviceType getDeviceType(double width) {
    if (width >= Breakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width >= Breakpoints.tablet) {
      return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = getDeviceType(constraints.maxWidth);
        return builder(context, deviceType, constraints);
      },
    );
  }
}

/// Responsive widget with different layouts
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, constraints) {
        switch (deviceType) {
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Responsive value helper
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  T get(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final deviceType = ResponsiveBuilder.getDeviceType(width);

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Extension for responsive padding
extension ResponsiveExtension on BuildContext {
  /// Get current device type
  DeviceType get deviceType {
    final width = MediaQuery.sizeOf(this).width;
    return ResponsiveBuilder.getDeviceType(width);
  }

  /// Check device type
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Responsive horizontal padding
  double get horizontalPadding {
    switch (deviceType) {
      case DeviceType.desktop:
        return 32;
      case DeviceType.tablet:
        return 24;
      case DeviceType.mobile:
        return 16;
    }
  }

  /// Max content width for cards
  double get maxCardWidth {
    switch (deviceType) {
      case DeviceType.desktop:
        return 400;
      case DeviceType.tablet:
        return 360;
      case DeviceType.mobile:
        return double.infinity;
    }
  }

  /// Grid columns for profile cards
  int get gridColumns {
    switch (deviceType) {
      case DeviceType.desktop:
        return 4;
      case DeviceType.tablet:
        return 2;
      case DeviceType.mobile:
        return 1;
    }
  }
}

/// Constrained width container for content
class ContentContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 600,
        ),
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: context.horizontalPadding,
        ),
        child: child,
      ),
    );
  }
}
