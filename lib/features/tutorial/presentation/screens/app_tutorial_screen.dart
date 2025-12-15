import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';

/// Provider to check if tutorial has been completed
final tutorialCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tutorial_completed') ?? false;
});

/// Provider to mark tutorial as completed
final markTutorialCompletedProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    ref.invalidate(tutorialCompletedProvider);
  };
});

/// Tutorial step data
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final String? animationHint;
  final Widget? customWidget;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.animationHint,
    this.customWidget,
  });
}

/// Interactive app tutorial screen
class AppTutorialScreen extends ConsumerStatefulWidget {
  const AppTutorialScreen({super.key});

  @override
  ConsumerState<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends ConsumerState<AppTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  late AnimationController _pulseController;
  late AnimationController _swipeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _swipeAnimation;

  final List<TutorialStep> _steps = [
    const TutorialStep(
      title: 'Welcome to FANCY!',
      description: 'Let us show you how to find your perfect match',
      icon: Icons.favorite,
    ),
    const TutorialStep(
      title: 'Tap to Expand',
      description: 'Single tap on a profile card to see it bigger',
      icon: Icons.touch_app,
      animationHint: 'tap',
    ),
    const TutorialStep(
      title: 'Swipe Photos',
      description: 'Swipe left or right on photos to see more',
      icon: Icons.swipe,
      animationHint: 'swipe_horizontal',
    ),
    const TutorialStep(
      title: 'Browse Profiles',
      description: 'Scroll up and down to see more profiles',
      icon: Icons.swap_vert,
      animationHint: 'scroll',
    ),
    const TutorialStep(
      title: 'Double Tap to Open',
      description: 'Double tap to view full profile details',
      icon: Icons.open_in_full,
      animationHint: 'double_tap',
    ),
    const TutorialStep(
      title: 'Like & Match',
      description: 'Swipe right or tap the heart to like someone.\nIf they like you back - it\'s a match!',
      icon: Icons.favorite_border,
      animationHint: 'like',
    ),
    const TutorialStep(
      title: 'Filters',
      description: 'Use filters to find exactly who you\'re looking for',
      icon: Icons.tune,
    ),
    const TutorialStep(
      title: 'Navigation',
      description: 'Home - Browse profiles\nChats - Your conversations\nProfile - Your settings',
      icon: Icons.navigation,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _swipeAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
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

  Future<void> _completeTutorial() async {
    await ref.read(markTutorialCompletedProvider)();
    if (mounted) {
      context.goToHome();
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  TextButton(
                    onPressed: _skipTutorial,
                    child: Text(
                      'Skip',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: List.generate(
                  _steps.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _buildStepContent(_steps[index]);
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    _currentStep < _steps.length - 1 ? 'Continue' : 'Get Started',
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

  Widget _buildStepContent(TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation area
          Expanded(
            child: Center(
              child: _buildAnimationWidget(step),
            ),
          ),

          // Text content
          Text(
            step.title,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapMd,
          Text(
            step.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapXxl,
        ],
      ),
    );
  }

  Widget _buildAnimationWidget(TutorialStep step) {
    switch (step.animationHint) {
      case 'tap':
        return _buildTapAnimation(step);
      case 'swipe_horizontal':
        return _buildSwipeAnimation(step);
      case 'scroll':
        return _buildScrollAnimation(step);
      case 'double_tap':
        return _buildDoubleTapAnimation(step);
      case 'like':
        return _buildLikeAnimation(step);
      default:
        return _buildDefaultIcon(step);
    }
  }

  Widget _buildDefaultIcon(TutorialStep step) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFE06B7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          step.icon,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTapAnimation(TutorialStep step) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Mock card
        Container(
          width: 200,
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[800]!, Colors.grey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 80, color: Colors.grey[600]),
              AppSpacing.vGapMd,
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        // Tap indicator
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.touch_app,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeAnimation(TutorialStep step) {
    return SlideTransition(
      position: _swipeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMiniPhoto(isActive: true),
          AppSpacing.hGapSm,
          _buildMiniPhoto(isActive: false),
          AppSpacing.hGapSm,
          _buildMiniPhoto(isActive: false),
        ],
      ),
    );
  }

  Widget _buildMiniPhoto({required bool isActive}) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFFE06B7A)],
              )
            : null,
        color: isActive ? null : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Icon(
        Icons.image,
        color: isActive ? Colors.white : Colors.grey[600],
        size: 30,
      ),
    );
  }

  Widget _buildScrollAnimation(TutorialStep step) {
    return AnimatedBuilder(
      animation: _swipeController,
      builder: (context, child) {
        final value = _swipeController.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -30 + value * 60),
              child: Opacity(
                opacity: 1 - value,
                child: _buildMiniCard(),
              ),
            ),
            Transform.translate(
              offset: Offset(0, value * 60),
              child: _buildMiniCard(highlight: true),
            ),
            Transform.translate(
              offset: Offset(0, 30 + value * 60),
              child: Opacity(
                opacity: value,
                child: _buildMiniCard(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniCard({bool highlight = false}) {
    return Container(
      width: 160,
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFFE06B7A)],
              )
            : null,
        color: highlight ? null : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight ? Colors.white.withOpacity(0.3) : Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 10,
                decoration: BoxDecoration(
                  color: highlight ? Colors.white.withOpacity(0.5) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AppSpacing.vGapXs,
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: highlight ? Colors.white.withOpacity(0.3) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleTapAnimation(TutorialStep step) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[800]!, Colors.grey[900]!],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
        // Double tap indicator
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _pulseController.value < 0.5 ? 1.2 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.touch_app, color: AppColors.primary),
                  ),
                ),
                AppSpacing.vGapXs,
                Transform.scale(
                  scale: _pulseController.value >= 0.5 ? 1.2 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.touch_app, color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLikeAnimation(TutorialStep step) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pass
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.grey[500], size: 30),
            ),
            AppSpacing.hGapXl,
            // Like heart
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.like, Color(0xFFFF6B8A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.like.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 40),
              ),
            ),
            AppSpacing.hGapXl,
            // Super like
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: AppColors.superLike, size: 30),
            ),
          ],
        );
      },
    );
  }
}
