import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../domain/providers/filter_provider.dart';

/// Filters screen
class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  FilterModel? _localFilter;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final filterAsync = ref.watch(filterAsyncProvider);

    return filterAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Filters')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Filters')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (filter) {
        // Initialize local filter only once when data is loaded
        if (!_isInitialized) {
          _localFilter = filter;
          _isInitialized = true;
        }

        final localFilter = _localFilter ?? filter;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Filters'),
            actions: [
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Dating goals
              _buildSection(
                'Dating Goals',
                _buildMultiSelectChips<DatingGoal>(
                  values: DatingGoal.values,
                  selected: localFilter.datingGoals,
                  labelBuilder: _getDatingGoalLabel,
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(datingGoals: values);
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Relationship status
              _buildSection(
                'Relationship Status',
                _buildMultiSelectChips<RelationshipStatus>(
                  values: RelationshipStatus.values,
                  selected: localFilter.relationshipStatuses,
                  labelBuilder: _getStatusLabel,
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(relationshipStatuses: values);
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Distance slider
              _buildSection(
                'Distance',
                FancySlider(
                  label: '',
                  value: localFilter.distanceKm.toDouble(),
                  min: FilterModel.minDistance.toDouble(),
                  max: FilterModel.maxDistance.toDouble(),
                  divisions: FilterModel.maxDistance - FilterModel.minDistance,
                  formatValue: (v) => v >= FilterModel.maxDistance ? '500+ km' : '${v.round()} km',
                  onChanged: (value) {
                    setState(() {
                      _localFilter = localFilter.copyWith(distanceKm: value.round());
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Age range
              _buildSection(
                'Age',
                FancyRangeSlider(
                  label: '',
                  values: RangeValues(
                    localFilter.minAge.toDouble(),
                    localFilter.maxAge.toDouble(),
                  ),
                  min: FilterModel.minAgeLimit.toDouble(),
                  max: FilterModel.maxAgeLimit.toDouble(),
                  divisions: FilterModel.maxAgeLimit - FilterModel.minAgeLimit,
                  formatValue: (v) => '${v.round()}',
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(
                        minAge: values.start.round(),
                        maxAge: values.end.round(),
                      );
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Special filters
              _buildSection(
                'Special Filters',
                Column(
                  children: [
                    _buildSwitchTile(
                      'Online only',
                      localFilter.onlineOnly,
                      (value) {
                        setState(() {
                          _localFilter = localFilter.copyWith(onlineOnly: value);
                        });
                      },
                    ),
                    _buildSwitchTile(
                      'With photo',
                      localFilter.withPhoto,
                      (value) {
                        setState(() {
                          _localFilter = localFilter.copyWith(withPhoto: value);
                        });
                      },
                    ),
                    _buildSwitchTile(
                      'Verified photos only',
                      localFilter.verifiedOnly,
                      (value) {
                        setState(() {
                          _localFilter = localFilter.copyWith(verifiedOnly: value);
                        });
                      },
                    ),
                  ],
                ),
              ),

              AppSpacing.vGapXl,

              // Looking for
              _buildSection(
                'Looking For',
                _buildMultiSelectChips<ProfileType>(
                  values: ProfileType.values,
                  selected: localFilter.lookingFor,
                  labelBuilder: _getProfileTypeLabel,
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(lookingFor: values);
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Height range
              _buildSection(
                'Height',
                FancyRangeSlider(
                  label: '',
                  values: RangeValues(
                    (localFilter.minHeight ?? FilterModel.minHeightLimit).toDouble(),
                    (localFilter.maxHeight ?? FilterModel.maxHeightLimit).toDouble(),
                  ),
                  min: FilterModel.minHeightLimit.toDouble(),
                  max: FilterModel.maxHeightLimit.toDouble(),
                  divisions: FilterModel.maxHeightLimit - FilterModel.minHeightLimit,
                  formatValue: (v) => '${v.round()} cm',
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(
                        minHeight: values.start.round(),
                        maxHeight: values.end.round(),
                      );
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Weight range
              _buildSection(
                'Weight',
                FancyRangeSlider(
                  label: '',
                  values: RangeValues(
                    (localFilter.minWeight ?? FilterModel.minWeightLimit).toDouble(),
                    (localFilter.maxWeight ?? FilterModel.maxWeightLimit).toDouble(),
                  ),
                  min: FilterModel.minWeightLimit.toDouble(),
                  max: FilterModel.maxWeightLimit.toDouble(),
                  divisions: FilterModel.maxWeightLimit - FilterModel.minWeightLimit,
                  formatValue: (v) => '${v.round()} kg',
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(
                        minWeight: values.start.round(),
                        maxWeight: values.end.round(),
                      );
                    });
                  },
                ),
              ),

              AppSpacing.vGapXl,

              // Zodiac signs
              _buildSection(
                'Zodiac Signs',
                _buildMultiSelectChips<ZodiacSign>(
                  values: ZodiacSign.values,
                  selected: localFilter.zodiacSigns,
                  labelBuilder: _getZodiacLabel,
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(zodiacSigns: values);
                    });
                  },
                ),
              ),

              AppSpacing.vGapXxl,
              AppSpacing.vGapXxl,
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FancyButton(
                text: 'Apply Filters',
                onPressed: _applyFilters,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vGapMd,
        child,
      ],
    );
  }

  Widget _buildMultiSelectChips<T>({
    required List<T> values,
    required Set<T> selected,
    required String Function(T) labelBuilder,
    required ValueChanged<Set<T>> onChanged,
  }) {
    return FancyChipWrap(
      children: values.map((value) {
        final isSelected = selected.contains(value);
        return FancyChip(
          label: labelBuilder(value),
          isSelected: isSelected,
          onTap: () {
            final newSet = Set<T>.from(selected);
            if (isSelected) {
              newSet.remove(value);
            } else {
              newSet.add(value);
            }
            onChanged(newSet);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.bodyMedium),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _localFilter = FilterModel.defaultFilters;
    });
  }

  void _applyFilters() async {
    if (_localFilter != null) {
      await ref.read(filterAsyncProvider.notifier).updateFilters(_localFilter!);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _getDatingGoalLabel(DatingGoal goal) {
    switch (goal) {
      case DatingGoal.anything:
        return 'Anything';
      case DatingGoal.casual:
        return 'Casual';
      case DatingGoal.virtual:
        return 'Virtual';
      case DatingGoal.friendship:
        return 'Friendship';
      case DatingGoal.longTerm:
        return 'Long-term';
    }
  }

  String _getStatusLabel(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.single:
        return 'Single';
      case RelationshipStatus.complicated:
        return 'Complicated';
      case RelationshipStatus.married:
        return 'Married';
      case RelationshipStatus.inRelationship:
        return 'In a relationship';
    }
  }

  String _getProfileTypeLabel(ProfileType type) {
    switch (type) {
      case ProfileType.woman:
        return 'Woman';
      case ProfileType.man:
        return 'Man';
      case ProfileType.manAndWoman:
        return 'Man & Woman';
      case ProfileType.manPair:
        return 'Man pair';
      case ProfileType.womanPair:
        return 'Woman pair';
    }
  }

  String _getZodiacLabel(ZodiacSign sign) {
    switch (sign) {
      case ZodiacSign.aries:
        return 'Aries';
      case ZodiacSign.taurus:
        return 'Taurus';
      case ZodiacSign.gemini:
        return 'Gemini';
      case ZodiacSign.cancer:
        return 'Cancer';
      case ZodiacSign.leo:
        return 'Leo';
      case ZodiacSign.virgo:
        return 'Virgo';
      case ZodiacSign.libra:
        return 'Libra';
      case ZodiacSign.scorpio:
        return 'Scorpio';
      case ZodiacSign.sagittarius:
        return 'Sagittarius';
      case ZodiacSign.capricorn:
        return 'Capricorn';
      case ZodiacSign.aquarius:
        return 'Aquarius';
      case ZodiacSign.pisces:
        return 'Pisces';
    }
  }
}
