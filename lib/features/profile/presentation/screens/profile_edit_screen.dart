import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/user_model.dart';
import '../../domain/providers/current_profile_provider.dart';

/// Profile edit screen
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  late DatingGoal? _selectedGoal;
  late RelationshipStatus? _selectedStatus;
  late ProfileType _selectedProfileType;
  late Set<String> _selectedInterests;
  late List<String> _selectedLanguages;

  final List<String> _availableInterests = [
    'Travel',
    'Music',
    'Sports',
    'Art',
    'Photography',
    'Movies',
    'Books',
    'Gaming',
    'Cooking',
    'Dancing',
    'Yoga',
    'Fitness',
    'Nature',
    'Technology',
    'Fashion',
  ];

  final List<String> _availableLanguages = [
    'English',
    'Russian',
    'French',
    'German',
    'Spanish',
    'Italian',
    'Chinese',
    'Japanese',
  ];

  @override
  void initState() {
    super.initState();
    final profileAsync = ref.read(currentProfileProvider);
    final user = profileAsync.valueOrNull;
    _bioController = TextEditingController(text: user?.bio);
    _occupationController = TextEditingController(text: user?.occupation);
    _selectedGoal = user?.datingGoal;
    _selectedStatus = user?.relationshipStatus;
    _selectedProfileType = user?.profileType ?? ProfileType.man;
    _selectedInterests = Set.from(user?.interests ?? []);
    _selectedLanguages = List.from(user?.languages ?? []);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Photos section
          _buildSection(
            'Photos',
            _buildPhotosGrid(),
          ),
          AppSpacing.vGapXl,

          // Bio
          _buildSection(
            'About Me',
            FancyInput(
              hint: 'Tell about yourself...',
              controller: _bioController,
              maxLines: 4,
              maxLength: 300,
            ),
          ),
          AppSpacing.vGapXl,

          // Dating goal
          _buildSection(
            'Dating Goal',
            _buildSingleSelect<DatingGoal>(
              values: DatingGoal.values,
              selected: _selectedGoal,
              labelBuilder: _getDatingGoalLabel,
              onChanged: (value) {
                setState(() => _selectedGoal = value);
              },
            ),
          ),
          AppSpacing.vGapXl,

          // Relationship status
          _buildSection(
            'Relationship Status',
            _buildSingleSelect<RelationshipStatus>(
              values: RelationshipStatus.values,
              selected: _selectedStatus,
              labelBuilder: _getStatusLabel,
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
          ),
          AppSpacing.vGapXl,

          // Profile type
          _buildSection(
            'Profile Type',
            _buildSingleSelect<ProfileType>(
              values: ProfileType.values,
              selected: _selectedProfileType,
              labelBuilder: _getProfileTypeLabel,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedProfileType = value);
                }
              },
            ),
          ),
          AppSpacing.vGapXl,

          // Interests
          _buildSection(
            'Interests (${_selectedInterests.length}/15)',
            FancyChipWrap(
              children: _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FancyChip(
                  label: interest,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest);
                      } else if (_selectedInterests.length < 15) {
                        _selectedInterests.add(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          AppSpacing.vGapXl,

          // Occupation
          _buildSection(
            'Occupation',
            FancyInput(
              hint: 'What do you do?',
              controller: _occupationController,
            ),
          ),
          AppSpacing.vGapXl,

          // Languages
          _buildSection(
            'Languages',
            FancyChipWrap(
              children: _availableLanguages.map((language) {
                final isSelected = _selectedLanguages.contains(language);
                return FancyChip(
                  label: language,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedLanguages.remove(language);
                      } else {
                        _selectedLanguages.add(language);
                      }
                    });
                  },
                );
              }).toList(),
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
            text: 'Save',
            onPressed: _saveProfile,
          ),
        ),
      ),
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

  Widget _buildPhotosGrid() {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = profileAsync.valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        if (index < user.photos.length) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.network(
                  user.photos[index],
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    // Delete photo
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return GestureDetector(
          onTap: () {
            // Add photo
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                color: AppColors.textTertiary,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleSelect<T>({
    required List<T> values,
    required T? selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return FancyChipWrap(
      children: values.map((value) {
        final isSelected = selected == value;
        return FancyChip(
          label: labelBuilder(value),
          isSelected: isSelected,
          onTap: () => onChanged(isSelected ? null : value),
        );
      }).toList(),
    );
  }

  Future<void> _saveProfile() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ref.read(currentProfileProvider.notifier).updateProfile(
        bio: _bioController.text.trim(),
        occupation: _occupationController.text.trim(),
        datingGoal: _selectedGoal,
        relationshipStatus: _selectedStatus,
        profileType: _selectedProfileType,
        interests: _selectedInterests.toList(),
        languages: _selectedLanguages,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save profile'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
}
