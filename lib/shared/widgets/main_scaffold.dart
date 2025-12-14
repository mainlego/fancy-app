import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../features/chats/domain/providers/chats_provider.dart';

/// Main scaffold with bottom navigation
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadChatsCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        unreadCount: unreadCount,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int unreadCount;

  const _BottomNavBar({
    required this.unreadCount,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/chats')) return 0;  // Chats is first
    if (location == '/') return 1;  // Home is second
    if (location.startsWith('/profile')) return 2;
    return 1;  // Default to home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // First: Chats
              _NavItem(
                iconPainter: _ChatsIconPainter(
                  color: currentIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                ),
                isActive: currentIndex == 0,
                badge: unreadCount > 0 ? unreadCount : null,
                onTap: () => context.goToChats(),
              ),
              // Second: Home
              _NavItem(
                iconPainter: _HomeIconPainter(
                  color: currentIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                ),
                isActive: currentIndex == 1,
                onTap: () => context.goToHome(),
              ),
              // Third: Profile
              _NavItem(
                iconPainter: _ProfileIconPainter(
                  color: currentIndex == 2 ? AppColors.primary : AppColors.textSecondary,
                ),
                isActive: currentIndex == 2,
                onTap: () => context.goToProfile(),
              ),
            ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final CustomPainter iconPainter;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPainter,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: const Size(24, 24),
              painter: iconPainter,
            ),
            if (badge != null)
              Positioned(
                right: 8,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Home icon painter - circle with leaf (swipe/discover icon)
class _HomeIconPainter extends CustomPainter {
  final Color color;

  _HomeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer circle
    canvas.drawCircle(
      Offset(16 * scale, 16 * scale),
      11.5 * scale,
      paint,
    );

    // Leaf path inside circle
    final leafPath = Path();
    leafPath.moveTo(18.6149 * scale, 13.9245 * scale);
    leafPath.cubicTo(19.6242 * scale, 14.9341 * scale, 20.2403 * scale, 16.3896 * scale, 20.6102 * scale, 17.7984 * scale);
    leafPath.cubicTo(20.9599 * scale, 19.1306 * scale, 21.0751 * scale, 20.3725 * scale, 21.1138 * scale, 21.0496 * scale);
    leafPath.cubicTo(20.4366 * scale, 21.0109 * scale, 19.1939 * scale, 20.8968 * scale, 17.8613 * scale, 20.547 * scale);
    leafPath.cubicTo(16.4523 * scale, 20.1771 * scale, 14.9974 * scale, 19.5604 * scale, 13.988 * scale, 18.5512 * scale);
    leafPath.cubicTo(12.9787 * scale, 17.5418 * scale, 12.3619 * scale, 16.0867 * scale, 11.9919 * scale, 14.6778 * scale);
    leafPath.cubicTo(11.6418 * scale, 13.3444 * scale, 11.5268 * scale, 12.1012 * scale, 11.4882 * scale, 11.4244 * scale);
    leafPath.cubicTo(12.1651 * scale, 11.4629 * scale, 13.4078 * scale, 11.5794 * scale, 14.7408 * scale, 11.9292 * scale);
    leafPath.cubicTo(16.1499 * scale, 12.299 * scale, 17.6055 * scale, 12.9149 * scale, 18.6149 * scale, 13.9245 * scale);
    leafPath.close();

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chats icon painter - chat bubble icon
class _ChatsIconPainter extends CustomPainter {
  final Color color;

  _ChatsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Chat bubble path
    final bubblePath = Path();
    // Main bubble shape
    bubblePath.moveTo(4 * scale, 18 * scale);
    bubblePath.lineTo(4 * scale, 6 * scale);
    bubblePath.cubicTo(4 * scale, 4.9 * scale, 4.9 * scale, 4 * scale, 6 * scale, 4 * scale);
    bubblePath.lineTo(18 * scale, 4 * scale);
    bubblePath.cubicTo(19.1 * scale, 4 * scale, 20 * scale, 4.9 * scale, 20 * scale, 6 * scale);
    bubblePath.lineTo(20 * scale, 14 * scale);
    bubblePath.cubicTo(20 * scale, 15.1 * scale, 19.1 * scale, 16 * scale, 18 * scale, 16 * scale);
    bubblePath.lineTo(8 * scale, 16 * scale);
    bubblePath.lineTo(4 * scale, 20 * scale);
    bubblePath.close();

    canvas.drawPath(bubblePath, paint);

    // Three dots inside bubble
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(8 * scale, 10 * scale), 1 * scale, dotPaint);
    canvas.drawCircle(Offset(12 * scale, 10 * scale), 1 * scale, dotPaint);
    canvas.drawCircle(Offset(16 * scale, 10 * scale), 1 * scale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Profile icon painter - exact Figma SVG
class _ProfileIconPainter extends CustomPainter {
  final Color color;

  _ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 30.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Body/shoulders arc
    final bodyPath = Path();
    bodyPath.moveTo(22.4168 * scale, 26.5714 * scale);
    bodyPath.cubicTo(22.1464 * scale, 25.0719 * scale, 21.2312 * scale, 23.7055 * scale, 19.8415 * scale, 22.7267 * scale);
    bodyPath.cubicTo(18.4518 * scale, 21.7478 * scale, 16.6826 * scale, 21.2234 * scale, 14.8633 * scale, 21.251 * scale);
    bodyPath.cubicTo(13.044 * scale, 21.2787 * scale, 11.2989 * scale, 21.8565 * scale, 9.95295 * scale, 22.8769 * scale);
    bodyPath.cubicTo(8.60703 * scale, 23.8973 * scale, 7.75214 * scale, 25.2906 * scale, 7.54756 * scale, 26.7973 * scale);

    canvas.drawPath(bodyPath, paint);

    // Head circle
    canvas.drawCircle(
      Offset(15 * scale, 12.5 * scale),
      3.75 * scale,
      paint,
    );

    // Rounded rectangle border
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * scale, 3 * scale, 24 * scale, 24 * scale),
      Radius.circular(3.5 * scale),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
