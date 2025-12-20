import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Chip variant types
enum FancyChipVariant {
  /// Standard selection chip (dating goals, status) - 4px vertical padding
  selection,
  /// Interest/fantasy tag in profile edit - 24px height, specific colors
  tag,
  /// Tag on profile view - can be matching or non-matching
  profileTag,
}

/// Colors for tag chips
const _tagSelectedBgColor = Color(0xFF291217);
const _tagTextColor = Color(0xFF8A5467);
const _profileTagNonMatchingBgColor = Color(0xFF0F0E0D);
const _profileTagNonMatchingTextColor = Color(0xFF4C4C4C);

/// FANCY styled chip for tags and filters
class FancyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool showRemove;
  final VoidCallback? onRemove;
  final FancyChipVariant variant;
  /// For profileTag variant: whether this tag matches the current user's tags
  final bool isMatching;

  const FancyChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.showRemove = false,
    this.onRemove,
    this.variant = FancyChipVariant.selection,
    this.isMatching = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors and padding based on variant
    Color bgColor;
    Color textColor;
    Color borderColor;
    double verticalPadding;
    double horizontalPadding;
    double? height;
    double fontSize;
    double letterSpacing;

    switch (variant) {
      case FancyChipVariant.selection:
        // Selection chips: 4px vertical padding
        bgColor = isSelected ? AppColors.primary : Colors.black;
        textColor = isSelected ? Colors.black : AppColors.textSecondary;
        borderColor = isSelected ? AppColors.primary : AppColors.border;
        verticalPadding = 4.0;
        horizontalPadding = AppSpacing.sm; // 8px
        height = null;
        fontSize = 14.0;
        letterSpacing = 0;
        break;

      case FancyChipVariant.tag:
        // Tag chips in profile edit: 24px height, specific colors
        bgColor = _tagSelectedBgColor;
        textColor = _tagTextColor;
        borderColor = _tagSelectedBgColor;
        verticalPadding = 4.0;
        horizontalPadding = AppSpacing.sm; // 8px
        height = 24.0;
        fontSize = 12.0;
        letterSpacing = -0.04 * 12.0; // -4% letter spacing
        break;

      case FancyChipVariant.profileTag:
        // Profile view tags: matching vs non-matching colors
        if (isMatching) {
          bgColor = _tagSelectedBgColor;
          textColor = _tagTextColor;
          borderColor = _tagSelectedBgColor;
        } else {
          bgColor = _profileTagNonMatchingBgColor;
          textColor = _profileTagNonMatchingTextColor;
          borderColor = _profileTagNonMatchingBgColor;
        }
        verticalPadding = 4.0;
        horizontalPadding = AppSpacing.sm; // 8px
        height = 24.0;
        fontSize = 12.0;
        letterSpacing = -0.04 * 12.0; // -4% letter spacing
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8), // 8px gap between items inside tag
        ],
        Text(
          label.toLowerCase(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            letterSpacing: letterSpacing,
            height: 1.2,
          ),
        ),
        if (showRemove) ...[
          const SizedBox(width: 8), // 8px gap between items inside tag
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 12,
              color: textColor,
            ),
          ),
        ],
      ],
    );

    // Use UnconstrainedBox to prevent the chip from expanding to fill available width
    return UnconstrainedBox(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: height != null ? 0 : verticalPadding,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: height != null
              ? Center(child: content)
              : content,
        ),
      ),
    );
  }
}

/// Wrap for multiple chips
/// Default spacing is 8px (gap between buttons per Figma design)
class FancyChipWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const FancyChipWrap({
    super.key,
    required this.children,
    this.spacing = 8.0, // 8px gap between chips
    this.runSpacing = 8.0, // 8px gap between rows
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
