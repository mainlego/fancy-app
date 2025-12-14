import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/models/user_model.dart';
import '../../domain/providers/current_profile_provider.dart';

/// Profile screen - exact Figma design
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading profile', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(currentProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.goToProfileSetup();
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  late List<DatingGoal> _selectedGoals;
  late RelationshipStatus? _selectedStatus;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    // Initialize from user data - support multiple goals
    _selectedGoals = widget.user.datingGoal != null ? [widget.user.datingGoal!] : [];
    _selectedStatus = widget.user.relationshipStatus;
    _isActive = widget.user.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Profile info block
                      _buildProfileInfoBlock(),
                      const SizedBox(height: 16),

                      // Photo gallery
                      _buildPhotoGallery(),
                      const SizedBox(height: 24),

                      // About me
                      _buildAboutMeSection(),
                      const SizedBox(height: 24),

                      // Dating goals
                      _buildDatingGoalsSection(),
                      const SizedBox(height: 24),

                      // Relationship status
                      _buildRelationshipStatusSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Activate profile button
            _buildActivateButton(),
          ],
        ),
      ),
    );
  }

  /// Header with X, title, gallery icon, settings icon
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // X button - go to home
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              context.goToHome();
            },
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.close,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),

          // Title centered
          Expanded(
            child: Text(
              'profile',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Gallery icon
          GestureDetector(
            onTap: () => context.pushAlbums(),
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.photo_library_outlined,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
          ),

          // Settings icon
          GestureDetector(
            onTap: () => context.pushSettings(),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Profile info block - avatar left, info right, edit button
  Widget _buildProfileInfoBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Image.network(
            widget.user.displayAvatar ?? '',
            width: 120,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              width: 120,
              height: 150,
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.person, size: 48, color: AppColors.textTertiary),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Info column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dating goal • relationship status
              Text(
                '${_getDatingGoalText(widget.user.datingGoal)} • ${_getStatusText(widget.user.relationshipStatus)}',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // online • verified
              Text(
                '${widget.user.isOnline ? 'online' : 'offline'} • ${widget.user.isVerified ? 'verified' : 'not verified'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),

              // location • distance
              Text(
                '${widget.user.locationString} • ${widget.user.distanceKm ?? 0} km',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Edit profile button
              GestureDetector(
                onTap: () => context.pushProfileEdit(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textPrimary, width: 1),
                  ),
                  child: Text(
                    'edit profile',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Photo gallery grid
  Widget _buildPhotoGallery() {
    final photos = widget.user.photos;
    const maxPhotos = 5;

    return Row(
      children: List.generate(maxPhotos, (index) {
        if (index < photos.length) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < maxPhotos - 1 ? 8 : 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    // Edit icon overlay
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Empty placeholder with dashed border
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < maxPhotos - 1 ? 8 : 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _DashedBorderPainter(color: AppColors.textTertiary),
                  child: Center(
                    child: index == photos.length
                        ? const Icon(Icons.add, color: AppColors.textTertiary, size: 24)
                        : null,
                  ),
                ),
              ),
            ),
          );
        }
      }),
    );
  }

  /// About me section
  Widget _buildAboutMeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About me',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Text(
            widget.user.bio ?? 'Share a few words about yourself, your interests, and what you\'re looking for in a connection...',
            style: AppTypography.bodyMedium.copyWith(
              color: widget.user.bio != null ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: AppColors.divider,
        ),
      ],
    );
  }

  /// Dating goals section with selectable chips
  Widget _buildDatingGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My dating goals',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DatingGoal.values.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
                _saveProfile();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    width: 1,
                  ),
                ),
                child: Text(
                  _getDatingGoalLabel(goal),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: AppColors.divider,
        ),
      ],
    );
  }

  /// Relationship status section with selectable chips
  Widget _buildRelationshipStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My relationship status',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RelationshipStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = isSelected ? null : status;
                });
                _saveProfile();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Activate profile button at bottom
  Widget _buildActivateButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isActive = !_isActive;
        });
        _saveProfile();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: _isActive ? AppColors.primary : AppColors.textTertiary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'activate profile',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                _isActive ? Icons.check_circle_outline : Icons.circle_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Get the first selected goal (for single-goal storage) or null if none selected
    final datingGoal = _selectedGoals.isNotEmpty ? _selectedGoals.first : null;

    await ref.read(currentProfileProvider.notifier).updateProfile(
      datingGoal: datingGoal,
      relationshipStatus: _selectedStatus,
      isActive: _isActive,
    );
  }

  String _getDatingGoalText(DatingGoal? goal) {
    if (goal == null) return 'not set';
    return _getDatingGoalLabel(goal);
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

  String _getStatusText(RelationshipStatus? status) {
    if (status == null) return 'not set';
    return _getStatusLabel(status);
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
}

/// Dashed border painter for empty photo slots
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 5.0;

    // Top
    _drawDashedLine(canvas, Offset.zero, Offset(size.width, 0), paint, dashWidth, dashSpace);
    // Right
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), paint, dashWidth, dashSpace);
    // Bottom
    _drawDashedLine(canvas, Offset(0, size.height), Offset(size.width, size.height), paint, dashWidth, dashSpace);
    // Left
    _drawDashedLine(canvas, Offset.zero, Offset(0, size.height), paint, dashWidth, dashSpace);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (dx * dx + dy * dy).abs();
    if (distance == 0) return;

    var currentX = start.dx;
    var currentY = start.dy;
    var drawn = 0.0;
    final totalLength = dx.abs() > dy.abs() ? dx.abs() : dy.abs();

    while (drawn < totalLength) {
      final dashEnd = (drawn + dashWidth).clamp(0.0, totalLength);
      canvas.drawLine(
        Offset(currentX, currentY),
        Offset(
          start.dx + (dx.abs() > 0 ? (dx > 0 ? dashEnd : -dashEnd) : 0),
          start.dy + (dy.abs() > 0 ? (dy > 0 ? dashEnd : -dashEnd) : 0),
        ),
        paint,
      );
      drawn += dashWidth + dashSpace;
      currentX = start.dx + (dx.abs() > 0 ? (dx > 0 ? drawn : -drawn) : 0);
      currentY = start.dy + (dy.abs() > 0 ? (dy > 0 ? drawn : -drawn) : 0);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
