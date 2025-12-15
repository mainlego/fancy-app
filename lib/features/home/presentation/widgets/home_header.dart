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

    _overlayEntry = OverlayEntry(
      builder: (context) => _FilterOverlay(
        onDismiss: () {
          // Save to database when closing
          final currentFilter = ref.read(filterAsyncProvider).valueOrNull ?? FilterModel.defaultFilters;
          final goals = ref.read(quickDatingGoalsProvider);
          final updatedFilter = currentFilter.copyWith(datingGoals: goals);
          ref.read(filterAsyncProvider.notifier).updateFilters(updatedFilter);
          _removeOverlay();
        },
        child: _DatingGoalPicker(
          ref: ref,
          onToggle: (goal) {
            final current = Set<DatingGoal>.from(ref.read(quickDatingGoalsProvider));
            if (goal == null) {
              // "all goals" selected - clear all
              ref.read(quickDatingGoalsProvider.notifier).state = <DatingGoal>{};
            } else if (current.contains(goal)) {
              current.remove(goal);
              ref.read(quickDatingGoalsProvider.notifier).state = current;
            } else {
              current.add(goal);
              ref.read(quickDatingGoalsProvider.notifier).state = current;
            }
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showStatusPicker(BuildContext context) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _FilterOverlay(
        onDismiss: () {
          // Save to database when closing
          final currentFilter = ref.read(filterAsyncProvider).valueOrNull ?? FilterModel.defaultFilters;
          final statuses = ref.read(quickRelationshipStatusesProvider);
          final updatedFilter = currentFilter.copyWith(relationshipStatuses: statuses);
          ref.read(filterAsyncProvider.notifier).updateFilters(updatedFilter);
          _removeOverlay();
        },
        child: _StatusPicker(
          ref: ref,
          onToggle: (status) {
            final current = Set<RelationshipStatus>.from(ref.read(quickRelationshipStatusesProvider));
            if (status == null) {
              // "all statuses" selected - clear all
              ref.read(quickRelationshipStatusesProvider.notifier).state = <RelationshipStatus>{};
            } else if (current.contains(status)) {
              current.remove(status);
              ref.read(quickRelationshipStatusesProvider.notifier).state = current;
            } else {
              current.add(status);
              ref.read(quickRelationshipStatusesProvider.notifier).state = current;
            }
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
    final selectedGoals = ref.watch(quickDatingGoalsProvider);
    final selectedStatuses = ref.watch(quickRelationshipStatusesProvider);
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
                _getDatingGoalsText(selectedGoals),
                style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Relationship status
          Expanded(
            child: GestureDetector(
              onTap: () => _showStatusPicker(context),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _getStatusesText(selectedStatuses),
                style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
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
                style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 16,
                  fontWeight: FontWeight.w200,
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

  String _getDatingGoalsText(Set<DatingGoal> goals) {
    if (goals.isEmpty) return 'all goals';
    if (goals.length == 1) {
      return _getSingleGoalText(goals.first);
    }
    // Show count for multiple
    return '${goals.length} goals';
  }

  String _getSingleGoalText(DatingGoal goal) {
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

  String _getStatusesText(Set<RelationshipStatus> statuses) {
    if (statuses.isEmpty) return 'all statuses';
    if (statuses.length == 1) {
      return _getSingleStatusText(statuses.first);
    }
    // Show count for multiple
    return '${statuses.length} statuses';
  }

  String _getSingleStatusText(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.single:
        return 'single';
      case RelationshipStatus.complicated:
        return 'complicated';
      case RelationshipStatus.married:
        return 'married';
      case RelationshipStatus.inRelationship:
        return 'in relationship';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth * 0.45; // ~1/2 width

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
          // Content centered horizontally
          Positioned(
            top: 80,
            left: (screenWidth - dropdownWidth) / 2,
            width: dropdownWidth,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Dating goal picker with multi-select support
class _DatingGoalPicker extends ConsumerWidget {
  final WidgetRef ref;
  final ValueChanged<DatingGoal?> onToggle;

  const _DatingGoalPicker({
    required this.ref,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(quickDatingGoalsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem('all goals', null, selected.isEmpty),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('anything', DatingGoal.anything, selected.contains(DatingGoal.anything)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('casual', DatingGoal.casual, selected.contains(DatingGoal.casual)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('virtual', DatingGoal.virtual, selected.contains(DatingGoal.virtual)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('friendship', DatingGoal.friendship, selected.contains(DatingGoal.friendship)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('long-term', DatingGoal.longTerm, selected.contains(DatingGoal.longTerm)),
        ],
      ),
    );
  }

  Widget _buildItem(String text, DatingGoal? goal, bool isSelected) {
    return GestureDetector(
      onTap: () => onToggle(goal),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected && goal != null)
              const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Status picker with multi-select support
class _StatusPicker extends ConsumerWidget {
  final WidgetRef ref;
  final ValueChanged<RelationshipStatus?> onToggle;

  const _StatusPicker({
    required this.ref,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(quickRelationshipStatusesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem('all statuses', null, selected.isEmpty),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('single', RelationshipStatus.single, selected.contains(RelationshipStatus.single)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('complicated', RelationshipStatus.complicated, selected.contains(RelationshipStatus.complicated)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('married', RelationshipStatus.married, selected.contains(RelationshipStatus.married)),
          const Divider(height: 1, color: AppColors.divider),
          _buildItem('in a relationship', RelationshipStatus.inRelationship, selected.contains(RelationshipStatus.inRelationship)),
        ],
      ),
    );
  }

  Widget _buildItem(String text, RelationshipStatus? status, bool isSelected) {
    return GestureDetector(
      onTap: () => onToggle(status),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected && status != null)
              const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 18,
              ),
          ],
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
                'distance',
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
              inactiveTrackColor: const Color(0xFFF2F2F2),
              thumbColor: const Color(0xFFF2F2F2),
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
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                'done',
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
