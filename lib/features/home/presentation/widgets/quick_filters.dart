import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/fancy_chip.dart';
import '../../../../shared/widgets/fancy_slider.dart';
import '../../../filters/domain/providers/filter_provider.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../domain/providers/profiles_provider.dart';

/// Quick filters bar on home screen
class QuickFilters extends ConsumerWidget {
  const QuickFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = ref.watch(quickDatingGoalProvider);
    final selectedStatus = ref.watch(quickRelationshipStatusProvider);
    final filter = ref.watch(filterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Dating goals row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _buildGoalChip(ref, null, 'All', selectedGoal),
                AppSpacing.hGapSm,
                _buildGoalChip(ref, DatingGoal.anything, 'Anything', selectedGoal),
                AppSpacing.hGapSm,
                _buildGoalChip(ref, DatingGoal.casual, 'Casual', selectedGoal),
                AppSpacing.hGapSm,
                _buildGoalChip(ref, DatingGoal.virtual, 'Virtual', selectedGoal),
                AppSpacing.hGapSm,
                _buildGoalChip(ref, DatingGoal.friendship, 'Friendship', selectedGoal),
                AppSpacing.hGapSm,
                _buildGoalChip(ref, DatingGoal.longTerm, 'Long-term', selectedGoal),
              ],
            ),
          ),
          AppSpacing.vGapSm,

          // Status row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _buildStatusChip(ref, null, 'All statuses', selectedStatus),
                AppSpacing.hGapSm,
                _buildStatusChip(ref, RelationshipStatus.single, 'Single', selectedStatus),
                AppSpacing.hGapSm,
                _buildStatusChip(ref, RelationshipStatus.complicated, 'Complicated', selectedStatus),
                AppSpacing.hGapSm,
                _buildStatusChip(ref, RelationshipStatus.married, 'Married', selectedStatus),
                AppSpacing.hGapSm,
                _buildStatusChip(ref, RelationshipStatus.inRelationship, 'In a relationship', selectedStatus),
              ],
            ),
          ),
          AppSpacing.vGapSm,

          // Distance slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FancySlider(
              label: 'Distance',
              value: filter.distanceKm.toDouble(),
              min: 1,
              max: 500,
              divisions: 499,
              formatValue: (v) => '${v.round()} km',
              onChanged: (value) {
                ref.read(filterNotifierProvider.notifier).updateDistance(value.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(
    WidgetRef ref,
    DatingGoal? goal,
    String label,
    DatingGoal? selected,
  ) {
    return FancyChip(
      label: label,
      isSelected: selected == goal,
      onTap: () {
        ref.read(quickDatingGoalProvider.notifier).state = goal;
      },
    );
  }

  Widget _buildStatusChip(
    WidgetRef ref,
    RelationshipStatus? status,
    String label,
    RelationshipStatus? selected,
  ) {
    return FancyChip(
      label: label,
      isSelected: selected == status,
      onTap: () {
        ref.read(quickRelationshipStatusProvider.notifier).state = status;
      },
    );
  }
}
