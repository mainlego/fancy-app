import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../domain/providers/filter_provider.dart';

/// Divider color for filters screen
const _dividerColor = Color(0xFF404040);

/// Available languages for filter
const _availableLanguages = <String, String>{
  'en': 'english',
  'de': 'deutsch',
  'fr': 'français',
  'es': 'español',
  'it': 'italiano',
  'pt': 'português',
  'ru': 'русский',
  'uk': 'українська',
  'pl': 'polski',
  'nl': 'nederlands',
  'tr': 'türkçe',
  'ar': 'العربية',
  'zh': '中文',
  'ja': '日本語',
  'ko': '한국어',
};

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
        appBar: AppBar(title: const Text('preferences')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('preferences')),
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
            title: const Text('preferences'),
            actions: [
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'reset',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Divider after header
              _buildDivider(),
              AppSpacing.vGapLg,

              // Dating goals
              _buildSection(
                'dating goals',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Relationship status
              _buildSection(
                'relationship status',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Distance range slider
              _buildSection(
                'distance',
                FancyRangeSlider(
                  label: '',
                  values: RangeValues(
                    localFilter.minDistanceKm.toDouble(),
                    localFilter.maxDistanceKm.toDouble(),
                  ),
                  min: FilterModel.minDistanceLimit.toDouble(),
                  max: FilterModel.maxDistanceLimit.toDouble(),
                  divisions: FilterModel.maxDistanceLimit - FilterModel.minDistanceLimit,
                  formatValue: (v) => v >= FilterModel.maxDistanceLimit ? '500+' : '${v.round()}',
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(
                        minDistanceKm: values.start.round(),
                        maxDistanceKm: values.end.round(),
                      );
                    });
                  },
                  subtitle: localFilter.maxDistanceKm >= FilterModel.maxDistanceLimit
                      ? 'search radius ${localFilter.minDistanceKm} - 500+ km'
                      : 'search radius ${localFilter.minDistanceKm} - ${localFilter.maxDistanceKm} km',
                ),
              ),

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Age range
              _buildSection(
                'age',
                FancyRangeSlider(
                  label: '',
                  values: RangeValues(
                    localFilter.minAge.toDouble(),
                    localFilter.maxAge.toDouble().clamp(18, 60), // UI shows max 60, but stores up to 99
                  ),
                  min: FilterModel.minAgeLimit.toDouble(),
                  max: 60, // Display limit is 60, 60+ means unlimited
                  divisions: 60 - FilterModel.minAgeLimit,
                  formatValue: (v) => v >= 60 ? '60+' : '${v.round()}',
                  onChanged: (values) {
                    setState(() {
                      _localFilter = localFilter.copyWith(
                        minAge: values.start.round(),
                        // When slider is at 60, store 99 (unlimited)
                        maxAge: values.end >= 60 ? 99 : values.end.round(),
                      );
                    });
                  },
                  subtitle: localFilter.maxAge >= 60
                      ? 'age range ${localFilter.minAge} - 60+ years'
                      : 'age range ${localFilter.minAge} - ${localFilter.maxAge} years',
                ),
              ),

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Special filters
              _buildSection(
                'special',
                Column(
                  children: [
                    _buildSwitchTile(
                      'online',
                      localFilter.onlineOnly,
                      (value) {
                        setState(() {
                          _localFilter = localFilter.copyWith(onlineOnly: value);
                        });
                      },
                    ),
                    _buildSwitchTile(
                      'photo',
                      localFilter.withPhoto,
                      (value) {
                        setState(() {
                          _localFilter = localFilter.copyWith(withPhoto: value);
                        });
                      },
                    ),
                    _buildSwitchTile(
                      'verified photo',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Looking for
              _buildSection(
                'looking for',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Height range
              _buildSection(
                'height',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Weight range
              _buildSection(
                'weight',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Zodiac signs
              _buildSection(
                'zodiac',
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

              AppSpacing.vGapLg,
              _buildDivider(),
              AppSpacing.vGapLg,

              // Language selection
              _buildSection(
                'language',
                _buildLanguageSelector(localFilter),
              ),

              AppSpacing.vGapXxl,
              AppSpacing.vGapXxl,
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FancyButton(
                text: 'apply filters',
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: _dividerColor,
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
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF737373),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(FilterModel localFilter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown button
        GestureDetector(
          onTap: () => _showLanguagePicker(localFilter),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.language,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    'select languages',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // Selected languages chips
        if (localFilter.languages.isNotEmpty) ...[
          AppSpacing.vGapMd,
          FancyChipWrap(
            children: localFilter.languages.map((langCode) {
              return FancyChip(
                label: _availableLanguages[langCode] ?? langCode,
                isSelected: true,
                showRemove: true,
                onRemove: () {
                  final newLanguages = Set<String>.from(localFilter.languages);
                  newLanguages.remove(langCode);
                  setState(() {
                    _localFilter = localFilter.copyWith(languages: newLanguages);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showLanguagePicker(FilterModel localFilter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'select languages',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  AppSpacing.vGapMd,
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableLanguages.length,
                      itemBuilder: (context, index) {
                        final entry = _availableLanguages.entries.elementAt(index);
                        final isSelected = (_localFilter ?? localFilter).languages.contains(entry.key);
                        return ListTile(
                          title: Text(
                            entry.value,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            final currentFilter = _localFilter ?? localFilter;
                            final newLanguages = Set<String>.from(currentFilter.languages);
                            if (isSelected) {
                              newLanguages.remove(entry.key);
                            } else {
                              newLanguages.add(entry.key);
                            }
                            setState(() {
                              _localFilter = currentFilter.copyWith(languages: newLanguages);
                            });
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  String _getStatusLabel(RelationshipStatus status) {
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

  String _getProfileTypeLabel(ProfileType type) {
    switch (type) {
      case ProfileType.woman:
        return 'woman';
      case ProfileType.man:
        return 'man';
      case ProfileType.manAndWoman:
        return 'man & woman';
      case ProfileType.manPair:
        return 'man pair';
      case ProfileType.womanPair:
        return 'woman pair';
    }
  }

  String _getZodiacLabel(ZodiacSign sign) {
    switch (sign) {
      case ZodiacSign.aries:
        return 'aries';
      case ZodiacSign.taurus:
        return 'taurus';
      case ZodiacSign.gemini:
        return 'gemini';
      case ZodiacSign.cancer:
        return 'cancer';
      case ZodiacSign.leo:
        return 'leo';
      case ZodiacSign.virgo:
        return 'virgo';
      case ZodiacSign.libra:
        return 'libra';
      case ZodiacSign.scorpio:
        return 'scorpio';
      case ZodiacSign.sagittarius:
        return 'sagittarius';
      case ZodiacSign.capricorn:
        return 'capricorn';
      case ZodiacSign.aquarius:
        return 'aquarius';
      case ZodiacSign.pisces:
        return 'pisces';
    }
  }
}
