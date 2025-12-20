import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';

/// Profile setup screen for new users
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  DatingGoal? _datingGoal;
  String? _city;
  double? _latitude;
  double? _longitude;
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isDetectingLocation = false;

  // Photo upload
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _birthDate != null && _calculateAge(_birthDate!) >= 18;
      case 2:
        return _gender != null;
      case 3:
        return _datingGoal != null;
      case 4:
        return true; // Bio is optional
      case 5:
        return _selectedPhoto != null; // Photo is required
      default:
        return true;
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

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    if (_birthDate == null || _gender == null || _datingGoal == null || _selectedPhoto == null) return;

    setState(() => _isLoading = true);

    try {
      // First upload the photo
      String? photoUrl;
      if (_selectedPhotoBytes != null) {
        final supabase = ref.read(supabaseServiceProvider);
        final userId = supabase.currentUser?.id;
        if (userId != null) {
          final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          photoUrl = await supabase.uploadProfilePhoto(
            userId: userId,
            fileName: fileName,
            bytes: _selectedPhotoBytes!,
          );
        }
      }

      final notifier = ref.read(currentProfileProvider.notifier);
      final success = await notifier.createProfile(
        name: _nameController.text.trim(),
        birthDate: _birthDate!,
        gender: _gender!,
        datingGoal: _datingGoal!,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        city: _city,
        latitude: _latitude,
        longitude: _longitude,
        photos: photoUrl != null ? [photoUrl] : null,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        // Navigate to home after profile setup
        context.goToHome();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create profile. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Step ${_currentStep + 1} of 6',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.zero,
              ),
            ),
            AppSpacing.vGapLg,

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildBirthDateStep(),
                  _buildGenderStep(),
                  _buildDatingGoalStep(),
                  _buildBioStep(),
                  _buildPhotoStep(),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed() && !_isLoading ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentStep < 5 ? 'Continue' : 'Complete',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your name?",
            style: AppTypography.displaySmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'This is how you will appear to others',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapXl,
          TextField(
            controller: _nameController,
            style: AppTypography.headlineSmall,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: AppTypography.headlineSmall.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateStep() {
    final age = _birthDate != null ? _calculateAge(_birthDate!) : 0;
    final isUnder18 = _birthDate != null && age < 18;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When were you born?',
            style: AppTypography.displaySmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'You must be at least 18 years old',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapXl,
          GestureDetector(
            onTap: () => _showDatePicker(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.zero,
                border: isUnder18
                    ? Border.all(color: AppColors.error)
                    : null,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.hGapMd,
                  Text(
                    _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Select your birth date',
                    style: AppTypography.headlineSmall.copyWith(
                      color: _birthDate != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_birthDate != null) ...[
            AppSpacing.vGapMd,
            Text(
              isUnder18
                  ? 'You must be at least 18 years old'
                  : 'You are $age years old',
              style: AppTypography.bodyMedium.copyWith(
                color: isUnder18 ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ],
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

  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your type of profile',
            style: AppTypography.displaySmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'Choose how you want to appear',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapXl,
          _buildGenderOption('male', 'Male', Icons.male),
          AppSpacing.vGapMd,
          _buildGenderOption('female', 'Female', Icons.female),
          AppSpacing.vGapMd,
          _buildGenderOption('other', 'Other', Icons.transgender),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;

    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            AppSpacing.hGapMd,
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatingGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you looking for?',
            style: AppTypography.displaySmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'Choose your dating goal',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapXl,
          _buildGoalOption(DatingGoal.longTerm, 'Long-term relationship', Icons.favorite),
          AppSpacing.vGapMd,
          _buildGoalOption(DatingGoal.casual, 'Casual dating', Icons.local_fire_department),
          AppSpacing.vGapMd,
          _buildGoalOption(DatingGoal.friendship, 'New friends', Icons.people),
          AppSpacing.vGapMd,
          _buildGoalOption(DatingGoal.virtual, 'Virtual connection', Icons.chat),
          AppSpacing.vGapMd,
          _buildGoalOption(DatingGoal.anything, 'Anything', Icons.explore),
        ],
      ),
    );
  }

  Widget _buildGoalOption(DatingGoal goal, String label, IconData icon) {
    final isSelected = _datingGoal == goal;

    return GestureDetector(
      onTap: () => setState(() => _datingGoal = goal),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: AppTypography.displaySmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'This is optional but helps others know you better',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapXl,
          TextField(
            controller: _bioController,
            style: AppTypography.bodyLarge,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Write something about yourself...',
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
              counterStyle: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          AppSpacing.vGapLg,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  onChanged: (value) => setState(() => _city = value),
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Your city (optional)',
                    hintStyle: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(Icons.location_on, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.lg),
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: IconButton(
                  onPressed: _isDetectingLocation ? null : _detectLocation,
                  icon: _isDetectingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                        ),
                  tooltip: 'Detect my location',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position != null) {
        // Save coordinates
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        // Reverse geocode to get city name using web-compatible API
        final cityName = await locationService.reverseGeocode(
          position.latitude,
          position.longitude,
        );

        if (cityName != null && cityName.isNotEmpty && mounted) {
          setState(() {
            _city = cityName;
            _cityController.text = cityName;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not determine city name'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your location. Please enable location services.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  Widget _buildPhotoStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your photo',
            style: AppTypography.displaySmall,
          ),
          AppSpacing.vGapSm,
          Text(
            'This will be your profile picture',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapXl,
          Center(
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickPhoto,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: _selectedPhoto != null ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: _isUploadingPhoto
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _selectedPhotoBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.zero,
                            child: Image.memory(
                              _selectedPhotoBytes!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              AppSpacing.vGapMd,
                              Text(
                                'Tap to add photo',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
          AppSpacing.vGapLg,
          if (_selectedPhoto != null)
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                label: Text(
                  'Change photo',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();

    // Show source selection dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.zero,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedPhoto = image;
          _selectedPhotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }
}
