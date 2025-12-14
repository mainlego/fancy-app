import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/pwa_update_service.dart';
import 'fancy_button.dart';

/// Dialog shown when a PWA update is available
class PwaUpdateDialog extends StatelessWidget {
  const PwaUpdateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PwaUpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.vGapLg,

            // Title
            Text(
              'Update Available',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vGapSm,

            // Description
            Text(
              'A new version of FANCY is available. Update now to get the latest features and improvements.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXl,

            // Update button
            FancyButton(
              text: 'Update Now',
              onPressed: () {
                Navigator.pop(context);
                PwaUpdateService().applyUpdate();
              },
            ),
            AppSpacing.vGapMd,

            // Later button
            FancyButton(
              text: 'Later',
              variant: FancyButtonVariant.ghost,
              onPressed: () {
                Navigator.pop(context);
                PwaUpdateService().skipUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that listens for PWA updates and shows dialog
class PwaUpdateListener extends StatefulWidget {
  final Widget child;

  const PwaUpdateListener({
    super.key,
    required this.child,
  });

  @override
  State<PwaUpdateListener> createState() => _PwaUpdateListenerState();
}

class _PwaUpdateListenerState extends State<PwaUpdateListener> {
  final _pwaService = PwaUpdateService();
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _pwaService.init();
    _pwaService.updateAvailable.listen((hasUpdate) {
      if (hasUpdate && mounted && !_dialogShown) {
        _dialogShown = true;
        PwaUpdateDialog.show(context).then((_) {
          _dialogShown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
