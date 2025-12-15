import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Slider thumb/track color
const _sliderThumbColor = Color(0xFFF2F2F2);
const _sliderInactiveTrackColor = Color(0xFFF2F2F2);
const _subtitleColor = Color(0xFF737373);

/// FANCY styled range slider
class FancyRangeSlider extends StatelessWidget {
  final String label;
  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value)? formatValue;
  final ValueChanged<RangeValues> onChanged;
  final String? subtitle;

  const FancyRangeSlider({
    super.key,
    required this.label,
    required this.values,
    required this.min,
    required this.max,
    this.divisions,
    this.formatValue,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final startLabel = formatValue?.call(values.start) ?? values.start.round().toString();
    final endLabel = formatValue?.call(values.end) ?? values.end.round().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.titleSmall),
              Text(
                '$startLabel - $endLabel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        if (label.isNotEmpty) AppSpacing.vGapSm,
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            thumbColor: _sliderThumbColor,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: _sliderInactiveTrackColor,
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: _subtitleColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// FANCY styled single slider
class FancySlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value)? formatValue;
  final ValueChanged<double> onChanged;
  final String? subtitle;

  const FancySlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.formatValue,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final valueLabel = formatValue?.call(value) ?? value.round().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.titleSmall),
              Text(
                valueLabel,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        if (label.isNotEmpty) AppSpacing.vGapSm,
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            thumbColor: _sliderThumbColor,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: _sliderInactiveTrackColor,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: _subtitleColor,
              ),
            ),
          ),
      ],
    );
  }
}
