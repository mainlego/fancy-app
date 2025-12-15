import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../../../tutorial/presentation/screens/app_tutorial_screen.dart';
import '../../domain/providers/profiles_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/match_dialog.dart';

/// Home screen with profile cards feed
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              FancyButton(
                text: 'Retry',
                onPressed: () => ref.refresh(currentProfileProvider),
              ),
            ],
          ),
        ),
      ),
      data: (currentProfile) {
        // If no profile exists, redirect to profile setup
        if (currentProfile == null) {
          // Schedule navigation after build
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

        // Check if tutorial has been completed
        final tutorialCompletedAsync = ref.watch(tutorialCompletedProvider);
        return tutorialCompletedAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _buildMainContent(context, ref), // On error, show main content
          data: (tutorialCompleted) {
            if (!tutorialCompleted) {
              // Schedule navigation to tutorial after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.goToTutorial();
                }
              });
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildMainContent(context, ref);
          },
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
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
    return ResponsiveBuilder(
      builder: (context, deviceType, constraints) {
        // Mobile: single column list with swipeable cards
        if (deviceType == DeviceType.mobile) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < profiles.length - 1 ? AppSpacing.lg : 0,
                ),
                child: SwipeableProfileCard(
                  user: profiles[index],
                  onDoubleTap: () => context.pushProfileView(profiles[index].id),
                  onLike: () => _handleLike(context, ref, profiles[index]),
                  onSuperLike: () => _handleSuperLike(context, ref, profiles[index]),
                  onHide: () => _hideUser(context, ref, profiles[index]),
                  onBlock: () => _blockUser(context, ref, profiles[index]),
                  onReport: () => _reportUser(context, ref, profiles[index]),
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
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            return SwipeableProfileCard(
              user: profiles[index],
              onDoubleTap: () => context.pushProfileView(profiles[index].id),
              onLike: () => _handleLike(context, ref, profiles[index]),
              onSuperLike: () => _handleSuperLike(context, ref, profiles[index]),
              onHide: () => _hideUser(context, ref, profiles[index]),
              onBlock: () => _blockUser(context, ref, profiles[index]),
              onReport: () => _reportUser(context, ref, profiles[index]),
            );
          },
        );
      },
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
          // Use correct route based on isAi flag
          if (user.isAi) {
            context.pushAIChat(user.id);
          } else {
            context.pushChatDetail(user.id);
          }
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
    // Super like - pass full UserModel for correct AI detection
    final isMatch = await ref.read(profilesNotifierProvider.notifier).likeUserModel(user);

    if (!context.mounted) return;

    if (isMatch) {
      // It's a match!
      MatchDialog.show(
        context,
        matchedUser: user,
        onSendMessage: () {
          // Use correct route based on isAi flag
          if (user.isAi) {
            context.pushAIChat(user.id);
          } else {
            context.pushChatDetail(user.id);
          }
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
