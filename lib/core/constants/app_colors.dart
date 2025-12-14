import 'package:flutter/material.dart';

/// FANCY app color palette
/// Based on Figma design system
abstract class AppColors {
  // === MAIN COLORS ===
  static const Color background = Color(0xFF000000); // main color 000000

  // === INTERFACE ELEMENTS ===
  static const Color primary = Color(0xFFD64557); // interface elements D64557
  static const Color primaryDark = Color(0xFFB33A4A);
  static const Color primaryLight = Color(0xFFE06B7A);

  // === LIKE BUTTONS ===
  static const Color like = Color(0xFFCC5B72); // like buttons CC5B72
  static const Color superLike = Color(0xFFCC5B72); // same as like

  // === TEXT COLORS ===
  static const Color textPrimary = Color(0xFFD9D9D9); // interface text (main) D9D9D9
  static const Color textSecondary = Color(0xFFB2B2B2); // interface icons + secondary B2B2B2
  static const Color textTertiary = Color(0xFF737373); // interface text inactive 737373
  static const Color textDisabled = Color(0xFF4C4C4C); // text tag inactive 4C4C4C
  static const Color infoText = Color(0xFFF2F2F2); // info text F2F2F2
  static const Color infoTextAdditional = Color(0xFFCCCCCC); // info text additional CCCCCC
  static const Color bioText = Color(0xFF999999); // bio text 999999
  static const Color explainText = Color(0xFF737373); // explaining text 737373

  // === SURFACE COLORS ===
  static const Color surface = Color(0xFF000000); // same as background
  static const Color surfaceVariant = Color(0xFF1F1D1B); // input 1F1D1B
  static const Color surfaceElevated = Color(0xFF2A2A2A);
  static const Color input = Color(0xFF1F1D1B); // input 1F1D1B

  // === DIVIDERS & BORDERS ===
  static const Color divider = Color(0xFF404040); // dividing line 404040
  static const Color border = Color(0xFF4C4C4C); // button stroke 4C4C4C
  static const Color borderFocused = Color(0xFFD64557);

  // === TAGS ===
  static const Color tagActive = Color(0xFF4A6A8A); // active/coincidence tags (blue-ish)
  static const Color tagInactive = Color(0xFF4C4C4C); // inactive/no coincidence 4C4C4C

  // === PREMIUM ===
  static const Color premium = Color(0xFFA7B4EC); // premium A7B4EC

  // === STATUS COLORS ===
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF757575);
  static const Color verified = Color(0xFF2196F3);
  static const Color pass = Color(0xFF757575);

  // === SYSTEM COLORS ===
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // === OVERLAY ===
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFE06B7A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );
}
