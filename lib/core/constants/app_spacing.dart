import 'package:flutter/material.dart';

/// FANCY app spacing constants
/// Based on Figma design system:
/// - отступ внутри кнопки: 4px (0.25 rem)
/// - отступ внутри кнопки: 8px (0.5 rem)
/// - отступ между краем экрана и контентом: 16px (1 rem)
/// - основной отступ между элементами: 16px (1 rem)
abstract class AppSpacing {
  // Base unit
  static const double unit = 4.0;

  // === CORE SPACING VALUES (from Figma) ===
  static const double xs = 4.0;   // 0.25 rem - внутри кнопки
  static const double sm = 8.0;   // 0.5 rem - внутри кнопки
  static const double md = 12.0;  // intermediate
  static const double lg = 16.0;  // 1 rem - основной отступ между элементами
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // === COMPONENT SPECIFIC ===
  static const double buttonPaddingInner = 4.0;  // отступ внутри кнопки 4px
  static const double buttonPadding = 8.0;       // отступ внутри кнопки 8px
  static const double screenPadding = 16.0;      // отступ между краем экрана и контентом 16px
  static const double elementSpacing = 16.0;     // основной отступ между элементами 16px
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double listItemSpacing = 12.0;

  // === BORDER RADIUS ===
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // === ICON SIZES ===
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // === AVATAR SIZES ===
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // === BUTTON HEIGHTS ===
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // === HELPER METHODS ===
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);

  // === COMMON PADDINGS ===
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenPadding);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  // === SIZEDBOX HELPERS ===
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);

  // === VERTICAL GAPS ===
  static const SizedBox vGapXs = SizedBox(height: xs);
  static const SizedBox vGapSm = SizedBox(height: sm);
  static const SizedBox vGapMd = SizedBox(height: md);
  static const SizedBox vGapLg = SizedBox(height: lg);
  static const SizedBox vGapXl = SizedBox(height: xl);
  static const SizedBox vGapXxl = SizedBox(height: xxl);

  // === HORIZONTAL GAPS ===
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
  static const SizedBox hGapXl = SizedBox(width: xl);
  static const SizedBox hGapXxl = SizedBox(width: xxl);
}
