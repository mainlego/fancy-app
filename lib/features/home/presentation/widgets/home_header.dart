import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../filters/presentation/screens/filters_screen.dart';
import '../../../filters/domain/providers/filter_provider.dart';
import '../../domain/providers/profiles_provider.dart';

/// Home header with filter items - exact Figma design
/// friendship | single | 99 km | filter_icon
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDatingGoalPicker(BuildContext context) {
    _removeOverlay();
    final selectedGoal = ref.read(quickDatingGoalProvider);

    _overlayEntry = OverlayEntry(
      builder: (context) => _FilterOverlay(
        onDismiss: _removeOverlay,
        child: _DatingGoalPicker(
          selected: selectedGoal,
          onSelect: (goal) {
            ref.read(quickDatingGoalProvider.notifier).state = goal;
            // Also update the main filter and save to database
            final currentFilter = ref.read(filterAsyncProvider).valueOrNull ?? FilterModel.defaultFilters;
            final updatedGoals = goal != null ? {goal} : <DatingGoal>{};
            final updatedFilter = currentFilter.copyWith(datingGoals: updatedGoals);
            ref.read(filterAsyncProvider.notifier).updateFilters(updatedFilter);
            _removeOverlay();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showStatusPicker(BuildContext context) {
    _removeOverlay();
    final selectedStatus = ref.read(quickRelationshipStatusProvider);

    _overlayEntry = OverlayEntry(
      builder: (context) => _FilterOverlay(
        onDismiss: _removeOverlay,
        child: _StatusPicker(
          selected: selectedStatus,
          onSelect: (status) {
            ref.read(quickRelationshipStatusProvider.notifier).state = status;
            // Also update the main filter and save to database
            final currentFilter = ref.read(filterAsyncProvider).valueOrNull ?? FilterModel.defaultFilters;
            final updatedStatuses = status != null ? {status} : <RelationshipStatus>{};
            final updatedFilter = currentFilter.copyWith(relationshipStatuses: updatedStatuses);
            ref.read(filterAsyncProvider.notifier).updateFilters(updatedFilter);
            _removeOverlay();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showDistanceSlider(BuildContext context) {
    _removeOverlay();
    final filter = ref.read(filterAsyncProvider).valueOrNull ?? FilterModel.defaultFilters;

    _overlayEntry = OverlayEntry(
      builder: (context) => _FilterOverlay(
        onDismiss: _removeOverlay,
        child: _DistanceSlider(
          value: filter.distanceKm.toDouble(),
          onChanged: (value) {
            ref.read(filterAsyncProvider.notifier).updateDistance(value.round());
          },
          onDone: _removeOverlay,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final selectedGoal = ref.watch(quickDatingGoalProvider);
    final selectedStatus = ref.watch(quickRelationshipStatusProvider);
    final filter = ref.watch(filterAsyncProvider).valueOrNull ?? FilterModel.defaultFilters;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.background,
      child: Row(
        children: [
          // Dating goal
          Expanded(
            child: GestureDetector(
              onTap: () => _showDatingGoalPicker(context),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _getDatingGoalText(selectedGoal),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Relationship status
          Expanded(
            child: GestureDetector(
              onTap: () => _showStatusPicker(context),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _getStatusText(selectedStatus),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Distance
          Expanded(
            child: GestureDetector(
              onTap: () => _showDistanceSlider(context),
              behavior: HitTestBehavior.opaque,
              child: Text(
                filter.distanceKm >= 500 ? '500+ km' : '${filter.distanceKm} km',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Filter icon
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FiltersScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.tune,
              color: AppColors.textSecondary,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ],
      ),
    );
  }

  String _getDatingGoalText(DatingGoal? goal) {
    if (goal == null) return 'all goals';
    switch (goal) {
      case DatingGoal.anything:
        return 'anything';
      case DatingGoal.casual:
        return 'casual';
      case DatingGoal.virtual:
        return 'virtual';
      case DatingGoal.friendship:
        return 'friendship';
      case DatingGoal.longTerm:
        return 'long-term';
    }
  }

  String _getStatusText(RelationshipStatus? status) {
    if (status == null) return 'all statuses';
    switch (status) {
      case RelationshipStatus.single:
        return 'single';
      case RelationshipStatus.complicated:
        return 'complicated';
      case RelationshipStatus.married:
        return 'married';
      case RelationshipStatus.inRelationship:
        return 'in a relationship';
    }
  }
}

/// Overlay wrapper for filter dropdowns
class _FilterOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final Widget child;

  const _FilterOverlay({
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Tap to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(color: Colors.black54),
            ),
          ),
          // Content centered
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Dating goal picker
class _DatingGoalPicker extends StatelessWidget {
  final DatingGoal? selected;
  final ValueChanged<DatingGoal?> onSelect;

  const _DatingGoalPicker({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem('all goals', null, selected == null),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('anything', DatingGoal.anything, selected == DatingGoal.anything),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('casual', DatingGoal.casual, selected == DatingGoal.casual),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('virtual', DatingGoal.virtual, selected == DatingGoal.virtual),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('friendship', DatingGoal.friendship, selected == DatingGoal.friendship),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('long-term', DatingGoal.longTerm, selected == DatingGoal.longTerm),
        ],
      ),
    );
  }

  Widget _buildItem(String text, DatingGoal? goal, bool isSelected) {
    return GestureDetector(
      onTap: () => onSelect(goal),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Status picker
class _StatusPicker extends StatelessWidget {
  final RelationshipStatus? selected;
  final ValueChanged<RelationshipStatus?> onSelect;

  const _StatusPicker({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem('all statuses', null, selected == null),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('single', RelationshipStatus.single, selected == RelationshipStatus.single),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('complicated', RelationshipStatus.complicated, selected == RelationshipStatus.complicated),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('married', RelationshipStatus.married, selected == RelationshipStatus.married),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('in a relationship', RelationshipStatus.inRelationship, selected == RelationshipStatus.inRelationship),
        ],
      ),
    );
  }

  Widget _buildItem(String text, RelationshipStatus? status, bool isSelected) {
    return GestureDetector(
      onTap: () => onSelect(status),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Distance slider
class _DistanceSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onDone;

  const _DistanceSlider({
    required this.value,
    required this.onChanged,
    required this.onDone,
  });

  @override
  State<_DistanceSlider> createState() => _DistanceSliderState();
}

class _DistanceSliderState extends State<_DistanceSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              Text(
                _currentValue >= 500 ? '500+ km' : '${_currentValue.round()} km',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _currentValue,
              min: 1,
              max: 500,
              divisions: 499,
              onChanged: (value) {
                setState(() => _currentValue = value);
                widget.onChanged(value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 km',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              Text(
                '500+',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: widget.onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
