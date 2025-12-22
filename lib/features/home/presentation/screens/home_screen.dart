import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/debug_panel.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/providers/profiles_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/match_dialog.dart';

/// Home screen with profile cards feed
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Check if user needs to complete profile setup
    final currentProfileAsync = ref.watch(currentProfileProvider);

    return currentProfileAsync.when(
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
              AppSpacing.vGapMd,
              Text('Error loading profile', style: AppTypography.bodyMedium),
              AppSpacing.vGapSm,
              Text(
                error.toString(),
                style: AppTypography.bodySmall.copyWith(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapMd,
              FancyButton(
                text: 'Retry',
                onPressed: () => ref.refresh(currentProfileProvider),
              ),
              AppSpacing.vGapSm,
              TextButton.icon(
                onPressed: () => DebugPanel.show(context),
                icon: const Icon(Icons.bug_report, color: AppColors.primary),
                label: Text('View Debug Logs', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
      data: (currentProfile) {
        // If no profile exists, user needs onboarding (new user)
        if (currentProfile == null) {
          // Schedule navigation after build
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (context.mounted) {
              // Check if onboarding was already shown
              final prefs = await SharedPreferences.getInstance();
              final onboardingCompleted = prefs.getBool(onboardingShownKey) ?? false;

              if (!onboardingCompleted) {
                // New user - show onboarding first, then profile setup
                context.goToOnboarding();
              } else {
                // Onboarding completed but no profile - go directly to profile setup
                context.goToProfileSetup();
              }
            }
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Profile exists but check if it's complete (has required fields)
        final isProfileComplete = currentProfile.name.isNotEmpty &&
            currentProfile.photos.isNotEmpty &&
            currentProfile.datingGoal != null;

        if (!isProfileComplete) {
          // Profile exists but is incomplete - go to profile setup
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.goToProfileSetup();
            }
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Profile exists and is complete, show main content
        return _buildMainContent(context, ref, currentProfile);
      },
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, UserModel currentProfile) {
    // Check if profile is active - if not, show activation required screen
    if (!currentProfile.isActive) {
      return _buildActivationRequiredScreen(context, ref);
    }

    final profilesAsync = ref.watch(profilesNotifierProvider);
    final profiles = ref.watch(filteredProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with filters
            const HomeHeader(),

            // Profiles - show AI profiles even while loading real ones
            Expanded(
              child: profiles.isEmpty
                  ? profilesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _buildErrorState(ref, error.toString()),
                      data: (_) => _buildEmptyState(ref),
                    )
                  : _buildProfilesGrid(context, ref, profiles),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationRequiredScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility_off_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.vGapXxl,

                // Title
                Text(
                  'Profile Not Active',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapMd,

                // Description
                Text(
                  'To browse and discover other profiles, you need to activate your profile first. '
                  'This makes your profile visible to others in their search results.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapXxl,

                // Activate button
                FancyButton(
                  text: 'Activate Profile',
                  onPressed: () async {
                    // Activate profile
                    final success = await ref.read(currentProfileProvider.notifier).updateProfile(
                      isActive: true,
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile activated! You can now browse profiles.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                AppSpacing.vGapMd,

                // Go to profile button
                FancyButton(
                  text: 'Go to Profile Settings',
                  variant: FancyButtonVariant.outline,
                  onPressed: () => context.goToProfile(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          AppSpacing.vGapLg,
          Text(
            'Failed to load profiles',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            error,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapXxl,
          FancyButton(
            text: 'Retry',
            variant: FancyButtonVariant.outline,
            fullWidth: false,
            onPressed: () {
              ref.read(profilesNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.vGapLg,
          Text(
            'No profiles found',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            'Try adjusting your filters or refresh',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          AppSpacing.vGapXxl,
          FancyButton(
            text: 'Refresh',
            variant: FancyButtonVariant.outline,
            fullWidth: false,
            onPressed: () {
              ref.read(profilesNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesGrid(BuildContext context, WidgetRef ref, List<UserModel> profiles) {
    final notifier = ref.read(profilesNotifierProvider.notifier);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load more when user scrolls near the bottom
        if (notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          final maxScrollExtent = notification.metrics.maxScrollExtent;
          // Load more when 80% scrolled
          if (pixels > maxScrollExtent * 0.8 && notifier.canLoadMore) {
            notifier.loadMore();
          }
        }
        return false;
      },
      child: ResponsiveBuilder(
        builder: (context, deviceType, constraints) {
          final hasMoreProfiles = notifier.canLoadMore;
          final isLoadingMore = notifier.isLoadingMore;
          final itemCount = profiles.length + (hasMoreProfiles ? 1 : 0);

          // Mobile: single column list with swipeable cards
          if (deviceType == DeviceType.mobile) {
            return ListView.builder(
              // No padding - card stretches 100% width
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Loading indicator at the end
                if (index >= profiles.length) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final profile = profiles[index];
                final isLiked = notifier.isProfileLiked(profile.id);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < profiles.length - 1 ? AppSpacing.lg : 0,
                  ),
                  child: SwipeableProfileCard(
                    user: profile,
                    isLiked: isLiked,
                    onDoubleTap: () => context.pushProfileView(profile.id),
                    onLike: () => _handleLike(context, ref, profile),
                    onSuperLike: () => _handleSuperLike(context, ref, profile),
                    onHide: () => _hideUser(context, ref, profile),
                    onBlock: () => _blockUser(context, ref, profile),
                    onReport: () => _reportUser(context, ref, profile),
                  ),
                );
              },
            );
          }

          // Tablet/Desktop: grid with swipeable cards
          final columns = deviceType == DeviceType.desktop ? 3 : 2;
          return GridView.builder(
            padding: EdgeInsets.all(context.horizontalPadding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.75,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Loading indicator at the end
              if (index >= profiles.length) {
                return Center(
                  child: isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                );
              }

              final profile = profiles[index];
              final isLiked = notifier.isProfileLiked(profile.id);

              return SwipeableProfileCard(
                user: profile,
                isLiked: isLiked,
                onDoubleTap: () => context.pushProfileView(profile.id),
                onLike: () => _handleLike(context, ref, profile),
                onSuperLike: () => _handleSuperLike(context, ref, profile),
                onHide: () => _hideUser(context, ref, profile),
                onBlock: () => _blockUser(context, ref, profile),
                onReport: () => _reportUser(context, ref, profile),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleLike(BuildContext context, WidgetRef ref, UserModel user) async {
    // Use Supabase like operation - pass full UserModel for correct AI detection
    final isMatch = await ref.read(profilesNotifierProvider.notifier).likeUserModel(user);

    if (!context.mounted) return;

    if (isMatch) {
      // It's a match!
      MatchDialog.show(
        context,
        matchedUser: user,
        onSendMessage: () {
          context.pushChatDetail(user.id);
        },
        onKeepBrowsing: () {},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Liked ${user.name}!'),
          backgroundColor: AppColors.like,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  Future<void> _handleSuperLike(BuildContext context, WidgetRef ref, UserModel user) async {
    // Super like
    final isMatch = await ref.read(profilesNotifierProvider.notifier).likeUserModel(user);

    if (!context.mounted) return;

    if (isMatch) {
      // It's a match!
      MatchDialog.show(
        context,
        matchedUser: user,
        onSendMessage: () {
          context.pushChatDetail(user.id);
        },
        onKeepBrowsing: () {},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Super liked ${user.name}!'),
          backgroundColor: AppColors.superLike,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  Future<void> _blockUser(BuildContext context, WidgetRef ref, UserModel user) async {
    try {
      await ref.read(profilesNotifierProvider.notifier).blockUser(user.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blocked ${user.name}'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to block user'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _hideUser(BuildContext context, WidgetRef ref, UserModel user) async {
    await ref.read(profilesNotifierProvider.notifier).passUser(user.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hidden ${user.name}'),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reportUser(BuildContext context, WidgetRef ref, UserModel user) async {
    // Show report dialog
    final reported = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Report ${user.name}?',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This profile will be reviewed by our team.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Report', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (reported == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reported ${user.name}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
