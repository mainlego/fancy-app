import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/fancy_button.dart';
import '../../domain/providers/auth_provider.dart';

/// Onboarding screen with welcome slides
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.favorite,
      title: 'Find Your Match',
      description: 'Discover people who share your interests and goals',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.chat_bubble,
      title: 'Connect & Chat',
      description: 'Start conversations with people you like',
      color: AppColors.superLike,
    ),
    _OnboardingPage(
      icon: Icons.verified_user,
      title: 'Safe & Verified',
      description: 'Photo verification ensures real connections',
      color: AppColors.verified,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingShownKey, true);

    if (mounted) {
      // After onboarding, go to profile setup
      context.goToProfileSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Skip',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildIndicator(index == _currentPage),
              ),
            ),
            AppSpacing.vGapXxl,

            // Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FancyButton(
                text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _nextPage,
              ),
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 70,
              color: page.color,
            ),
          ),
          AppSpacing.vGapXxl,
          AppSpacing.vGapXxl,

          // Title
          Text(
            page.title,
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapLg,

          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
