import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/data/profile_data.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/user_model.dart';
import '../../domain/providers/current_profile_provider.dart';
import '../../domain/providers/profile_options_provider.dart';

/// Profile edit screen
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _bioController;
  late DatingGoal? _selectedGoal;
  late RelationshipStatus? _selectedStatus;
  late ProfileType _selectedProfileType;
  Set<String> _selectedInterestIds = {};
  Set<String> _selectedFantasyIds = {};
  late List<String> _selectedLanguages;
  String? _selectedOccupationId;
  DateTime? _birthDate;
  bool _isLoadingSelections = true;

  @override
  void initState() {
    super.initState();
    final profileAsync = ref.read(currentProfileProvider);
    final user = profileAsync.valueOrNull;
    _bioController = TextEditingController(text: user?.bio);
    _selectedGoal = user?.datingGoal;
    _selectedStatus = user?.relationshipStatus;
    _selectedProfileType = user?.profileType ?? ProfileType.man;
    _selectedLanguages = List.from(user?.languages ?? []);
    _birthDate = user?.birthDate;
    _loadUserSelections();
  }

  Future<void> _loadUserSelections() async {
    final selectionsNotifier = ref.read(userSelectionsProvider.notifier);
    await selectionsNotifier.loadUserSelections();
    final selections = ref.read(userSelectionsProvider);
    if (mounted) {
      setState(() {
        _selectedInterestIds = Set.from(selections.selectedInterestIds);
        _selectedFantasyIds = Set.from(selections.selectedFantasyIds);
        _selectedOccupationId = selections.selectedOccupationId;
        _isLoadingSelections = false;
      });
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('edit profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Photos & Videos section
          _buildSectionBlock(
            'Photos & Videos',
            _buildPhotosGrid(),
          ),

          _buildDivider(),

          // About me section
          _buildSectionBlock(
            'About me',
            FancyInput(
              hint: 'Share a few words about yourself, your interests, and what you\'re looking for in a connection...',
              controller: _bioController,
              maxLines: 4,
              maxLength: 300,
            ),
          ),

          _buildDivider(),

          // My dating goals section
          _buildSectionBlock(
            'My dating goals',
            _buildSingleSelect<DatingGoal>(
              values: DatingGoal.values,
              selected: _selectedGoal,
              labelBuilder: _getDatingGoalLabel,
              onChanged: (value) {
                setState(() => _selectedGoal = value);
              },
            ),
          ),

          _buildDivider(),

          // My relationship status section
          _buildSectionBlock(
            'My relationship status',
            _buildSingleSelect<RelationshipStatus>(
              values: RelationshipStatus.values,
              selected: _selectedStatus,
              labelBuilder: _getStatusLabel,
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
          ),

          _buildDivider(),

          // I enjoy section (combined interests + fantasies)
          _buildIEnjoySection(),

          _buildDivider(),

          // My details section
          _buildMyDetailsSection(),

          const SizedBox(height: 100), // Space for save button
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: FancyButton(
            text: 'Save',
            onPressed: _saveProfile,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildSectionBlock(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildIEnjoySection() {
    final optionsState = ref.watch(profileOptionsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I enjoy',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adding your interests & temptations is a great way to find like-minded connections. Add 5-15 tags.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Interests search field
          _buildTagSearchField(
            hint: 'Find your interests.',
            selectedIds: _selectedInterestIds,
            items: optionsState.interests,
            itemNameGetter: (i) => (i as Interest).name,
            itemIdGetter: (i) => (i as Interest).id,
            maxItems: 20,
            onTap: () => _showInterestsBottomSheet(optionsState),
            isLoading: _isLoadingSelections || optionsState.isLoading,
          ),
          const SizedBox(height: 16),

          // Selected interests as tags
          if (_selectedInterestIds.isNotEmpty) ...[
            FancyChipWrap(
              children: _selectedInterestIds.map((id) {
                final interest = optionsState.interests.firstWhere(
                  (i) => i.id == id,
                  orElse: () => Interest(id: id, name: 'Unknown', category: 'Other'),
                );
                return FancyChip(
                  label: interest.name,
                  variant: FancyChipVariant.tag,
                  showRemove: true,
                  onRemove: () {
                    setState(() {
                      _selectedInterestIds.remove(id);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Fantasies search field
          _buildTagSearchField(
            hint: 'Find your temptations.',
            selectedIds: _selectedFantasyIds,
            items: optionsState.fantasies,
            itemNameGetter: (f) => (f as Fantasy).name,
            itemIdGetter: (f) => (f as Fantasy).id,
            maxItems: 15,
            onTap: () => _showFantasiesBottomSheet(optionsState),
            isLoading: _isLoadingSelections || optionsState.isLoading,
          ),
          const SizedBox(height: 16),

          // Selected fantasies as tags
          if (_selectedFantasyIds.isNotEmpty)
            FancyChipWrap(
              children: _selectedFantasyIds.map((id) {
                final fantasy = optionsState.fantasies.firstWhere(
                  (f) => f.id == id,
                  orElse: () => Fantasy(id: id, name: 'Unknown'),
                );
                return FancyChip(
                  label: fantasy.name,
                  variant: FancyChipVariant.tag,
                  showRemove: true,
                  onRemove: () {
                    setState(() {
                      _selectedFantasyIds.remove(id);
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTagSearchField({
    required String hint,
    required Set<String> selectedIds,
    required List<dynamic> items,
    required String Function(dynamic) itemNameGetter,
    required String Function(dynamic) itemIdGetter,
    required int maxItems,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    if (isLoading) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          hint,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildMyDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My details',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Profile type
          _buildDetailItem('Profile Type', _buildProfileTypeSelector()),
          const SizedBox(height: 16),

          // Birth Date
          _buildDetailItem('Birth Date', _buildBirthDatePicker()),
          const SizedBox(height: 16),

          // Occupation
          _buildDetailItem('Occupation', _buildOccupationSelector()),
          const SizedBox(height: 16),

          // Languages
          _buildDetailItem(
            'Languages',
            FancyChipWrap(
              children: ProfileLanguages.all.map((language) {
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
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  bool _isUploadingPhoto = false;

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
                borderRadius: BorderRadius.zero,
                child: Image.network(
                  user.photos[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: AppColors.textTertiary),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _deletePhoto(user.photos[index]),
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
              if (index == 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      'Main',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return GestureDetector(
          onTap: _isUploadingPhoto ? null : _addPhoto,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: _isUploadingPhoto && index == user.photos.length
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
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

  Future<void> _addPhoto() async {
    final picker = ImagePicker();

    // Show picker source dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Photo',
                style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              AppSpacing.vGapLg,
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('Camera', style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('Gallery', style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              AppSpacing.vGapMd,
              FancyButton(
                text: 'Cancel',
                variant: FancyButtonVariant.ghost,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      final url = await ref.read(currentProfileProvider.notifier).addPhoto(fileName, bytes);

      if (mounted) {
        setState(() => _isUploadingPhoto = false);

        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(String photoUrl) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Photo?',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref.read(currentProfileProvider.notifier).removePhoto(photoUrl);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete photo'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildBirthDatePicker() {
    final age = _birthDate != null ? _calculateAge(_birthDate!) : null;

    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Select your birth date',
                    style: AppTypography.titleSmall.copyWith(
                      color: _birthDate != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$age years old',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final initialDate = _birthDate ?? DateTime(now.year - 25);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: AppColors.surface,
        child: Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate.isBefore(maxDate) ? initialDate : maxDate,
                minimumDate: minDate,
                maximumDate: maxDate,
                onDateTimeChanged: (date) {
                  setState(() => _birthDate = date);
                },
              ),
            ),
          ],
        ),
      ),
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
      // Save profile data
      final profileSuccess = await ref.read(currentProfileProvider.notifier).updateProfile(
        bio: _bioController.text.trim(),
        birthDate: _birthDate,
        datingGoal: _selectedGoal,
        relationshipStatus: _selectedStatus,
        profileType: _selectedProfileType,
        languages: _selectedLanguages,
      );

      // Save selections (interests, fantasies, occupation)
      final selectionsNotifier = ref.read(userSelectionsProvider.notifier);
      // Update local state in provider
      for (final id in _selectedInterestIds) {
        if (!ref.read(userSelectionsProvider).selectedInterestIds.contains(id)) {
          selectionsNotifier.toggleInterest(id);
        }
      }
      for (final id in ref.read(userSelectionsProvider).selectedInterestIds) {
        if (!_selectedInterestIds.contains(id)) {
          selectionsNotifier.toggleInterest(id);
        }
      }
      for (final id in _selectedFantasyIds) {
        if (!ref.read(userSelectionsProvider).selectedFantasyIds.contains(id)) {
          selectionsNotifier.toggleFantasy(id);
        }
      }
      for (final id in ref.read(userSelectionsProvider).selectedFantasyIds) {
        if (!_selectedFantasyIds.contains(id)) {
          selectionsNotifier.toggleFantasy(id);
        }
      }
      selectionsNotifier.setOccupation(_selectedOccupationId);

      final selectionsSuccess = await selectionsNotifier.saveSelections();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (profileSuccess && selectionsSuccess) {
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

  Widget _buildProfileTypeSelector() {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = profileAsync.valueOrNull;
    final canChange = user?.canChangeProfileType ?? true;

    if (!canChange) {
      // Show locked state with current profile type
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: AppColors.textTertiary, size: 18),
                AppSpacing.hGapSm,
                Text(
                  _getProfileTypeLabel(_selectedProfileType),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              'Profile type can only be changed once. Contact support for assistance.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // Show editable state with warning
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSingleSelect<ProfileType>(
          values: ProfileType.values,
          selected: _selectedProfileType,
          labelBuilder: _getProfileTypeLabel,
          onChanged: (value) {
            if (value != null && value != user?.profileType) {
              // Show confirmation dialog before changing
              _showProfileTypeChangeConfirmation(value);
            } else if (value != null) {
              setState(() => _selectedProfileType = value);
            }
          },
        ),
        AppSpacing.vGapSm,
        Text(
          '⚠️ Profile type can only be changed once',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  void _showProfileTypeChangeConfirmation(ProfileType newType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Change Profile Type?',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to change your profile type to "${_getProfileTypeLabel(newType)}".',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vGapMd,
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.warning, size: 20),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      'This can only be done once. To change it again, you will need to contact support.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedProfileType = newType);
            },
            child: const Text('Confirm', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showInterestsBottomSheet(ProfileOptionsState optionsState) {
    final searchController = TextEditingController();
    List<Interest> filteredInterests = optionsState.interests;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Interests (${_selectedInterestIds.length}/20)',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      // Search field
                      TextField(
                        controller: searchController,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search interests...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            filteredInterests = ref.read(profileOptionsProvider.notifier).searchInterests(query);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Interests by category
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: _buildInterestCategories(filteredInterests, setModalState),
                  ),
                ),
                // Add custom button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: FancyButton(
                            text: 'Add Custom',
                            variant: FancyButtonVariant.outline,
                            onPressed: () => _showAddCustomInterestDialog(setModalState),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: FancyButton(
                            text: 'Done',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildInterestCategories(List<Interest> interests, StateSetter setModalState) {
    // Group by category
    final byCategory = <String, List<Interest>>{};
    for (final interest in interests) {
      byCategory.putIfAbsent(interest.category, () => []).add(interest);
    }

    final widgets = <Widget>[];
    for (final entry in byCategory.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(
            entry.key,
            style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
      widgets.add(
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: entry.value.map((interest) {
            final isSelected = _selectedInterestIds.contains(interest.id);
            return FancyChip(
              label: interest.name,
              isSelected: isSelected,
              onTap: () {
                setModalState(() {
                  if (isSelected) {
                    _selectedInterestIds.remove(interest.id);
                  } else if (_selectedInterestIds.length < 20) {
                    _selectedInterestIds.add(interest.id);
                  }
                });
                setState(() {});
              },
            );
          }).toList(),
        ),
      );
    }
    return widgets;
  }

  void _showAddCustomInterestDialog(StateSetter setModalState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Custom Interest',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter interest name',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final interest = await ref.read(profileOptionsProvider.notifier).addCustomInterest(name);
                if (interest != null && _selectedInterestIds.length < 20) {
                  setModalState(() {
                    _selectedInterestIds.add(interest.id);
                  });
                  setState(() {});
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showFantasiesBottomSheet(ProfileOptionsState optionsState) {
    final searchController = TextEditingController();
    List<Fantasy> filteredFantasies = optionsState.fantasies;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Fantasies (${_selectedFantasyIds.length}/15)',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      // Search field
                      TextField(
                        controller: searchController,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search fantasies...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            filteredFantasies = ref.read(profileOptionsProvider.notifier).searchFantasies(query);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Fantasies list
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: filteredFantasies.map((fantasy) {
                          final isSelected = _selectedFantasyIds.contains(fantasy.id);
                          return FancyChip(
                            label: fantasy.name,
                            isSelected: isSelected,
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  _selectedFantasyIds.remove(fantasy.id);
                                } else if (_selectedFantasyIds.length < 15) {
                                  _selectedFantasyIds.add(fantasy.id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Add custom button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: FancyButton(
                            text: 'Add Custom',
                            variant: FancyButtonVariant.outline,
                            onPressed: () => _showAddCustomFantasyDialog(setModalState),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: FancyButton(
                            text: 'Done',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomFantasyDialog(StateSetter setModalState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Custom Fantasy',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter fantasy name',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final fantasy = await ref.read(profileOptionsProvider.notifier).addCustomFantasy(name);
                if (fantasy != null && _selectedFantasyIds.length < 15) {
                  setModalState(() {
                    _selectedFantasyIds.add(fantasy.id);
                  });
                  setState(() {});
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupationSelector() {
    final optionsState = ref.watch(profileOptionsProvider);

    if (_isLoadingSelections || optionsState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectedOccupation = _selectedOccupationId != null
        ? optionsState.occupations.firstWhere(
            (o) => o.id == _selectedOccupationId,
            orElse: () => Occupation(id: '', name: 'Unknown'),
          )
        : null;

    return GestureDetector(
      onTap: () => _showOccupationBottomSheet(optionsState),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            const Icon(Icons.work_outline, color: AppColors.textSecondary),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                selectedOccupation?.name ?? 'Select your occupation',
                style: AppTypography.titleSmall.copyWith(
                  color: selectedOccupation != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showOccupationBottomSheet(ProfileOptionsState optionsState) {
    final searchController = TextEditingController();
    List<Occupation> filteredOccupations = optionsState.occupations;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Occupation',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      // Search field
                      TextField(
                        controller: searchController,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search occupations...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            filteredOccupations = ref.read(profileOptionsProvider.notifier).searchOccupations(query);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Clear selection option
                if (_selectedOccupationId != null)
                  ListTile(
                    leading: const Icon(Icons.clear, color: AppColors.error),
                    title: Text(
                      'Clear selection',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedOccupationId = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                // Occupations list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredOccupations.length,
                    itemBuilder: (context, index) {
                      final occupation = filteredOccupations[index];
                      final isSelected = _selectedOccupationId == occupation.id;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        ),
                        title: Text(
                          occupation.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedOccupationId = occupation.id;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                // Add custom button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: FancyButton(
                      text: 'Add Custom Occupation',
                      variant: FancyButtonVariant.outline,
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddCustomOccupationDialog();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomOccupationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Custom Occupation',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter occupation name',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final occupation = await ref.read(profileOptionsProvider.notifier).addCustomOccupation(name);
                if (occupation != null) {
                  setState(() {
                    _selectedOccupationId = occupation.id;
                  });
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
