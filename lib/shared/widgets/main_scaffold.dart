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
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
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
              _NavItem(
                iconPainter: _HomeIconPainter(
                  color: currentIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                ),
                isActive: currentIndex == 0,
                onTap: () => context.goToHome(),
              ),
              _NavItem(
                iconPainter: _ChatsIconPainter(
                  color: currentIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                ),
                isActive: currentIndex == 1,
                badge: unreadCount > 0 ? unreadCount : null,
                onTap: () => context.goToChats(),
              ),
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

/// Home icon painter - exact Figma SVG
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

    // House body path
    final housePath = Path();
    housePath.moveTo(5.33301 * scale, 13.1385 * scale);
    housePath.cubicTo(5.33301 * scale, 11.9357 * scale, 5.33301 * scale, 11.3343 * scale, 5.63171 * scale, 10.8509 * scale);
    housePath.cubicTo(5.9304 * scale, 10.3676 * scale, 6.46832 * scale, 10.0987 * scale, 7.54415 * scale, 9.56077 * scale);
    housePath.lineTo(14.2108 * scale, 6.22744 * scale);
    housePath.cubicTo(15.0886 * scale, 5.78853 * scale, 15.5275 * scale, 5.56908 * scale, 15.9997 * scale, 5.56908 * scale);
    housePath.cubicTo(16.4718 * scale, 5.56908 * scale, 16.9107 * scale, 5.78853 * scale, 17.7885 * scale, 6.22743 * scale);
    housePath.lineTo(24.4552 * scale, 9.56077 * scale);
    housePath.cubicTo(25.531 * scale, 10.0987 * scale, 26.0689 * scale, 10.3676 * scale, 26.3676 * scale, 10.8509 * scale);
    housePath.cubicTo(26.6663 * scale, 11.3343 * scale, 26.6663 * scale, 11.9357 * scale, 26.6663 * scale, 13.1385 * scale);
    housePath.lineTo(26.6663 * scale, 22.6663 * scale);
    housePath.cubicTo(26.6663 * scale, 24.552 * scale, 26.6663 * scale, 25.4948 * scale, 26.0806 * scale, 26.0806 * scale);
    housePath.cubicTo(25.4948 * scale, 26.6663 * scale, 24.552 * scale, 26.6663 * scale, 22.6663 * scale, 26.6663 * scale);
    housePath.lineTo(9.33301 * scale, 26.6663 * scale);
    housePath.cubicTo(7.44739 * scale, 26.6663 * scale, 6.50458 * scale, 26.6663 * scale, 5.91879 * scale, 26.0806 * scale);
    housePath.cubicTo(5.33301 * scale, 25.4948 * scale, 5.33301 * scale, 24.552 * scale, 5.33301 * scale, 22.6663 * scale);
    housePath.close();

    canvas.drawPath(housePath, paint);

    // Roof detail line
    final roofPath = Path();
    roofPath.moveTo(5.33301 * scale, 13.333 * scale);
    roofPath.lineTo(8.74722 * scale, 16.7472 * scale);
    roofPath.cubicTo(9.12229 * scale, 17.1223 * scale, 9.631 * scale, 17.333 * scale, 10.1614 * scale, 17.333 * scale);
    roofPath.lineTo(21.8379 * scale, 17.333 * scale);
    roofPath.cubicTo(22.3683 * scale, 17.333 * scale, 22.8771 * scale, 17.1223 * scale, 23.2521 * scale, 16.7472 * scale);
    roofPath.lineTo(26.6663 * scale, 13.333 * scale);

    canvas.drawPath(roofPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chats icon painter - exact Figma SVG (globe with leaf)
class _ChatsIconPainter extends CustomPainter {
  final Color color;

  _ChatsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Leaf shape inside globe
    final leafPath = Path();
    leafPath.moveTo(18.6154 * scale, 13.9245 * scale);
    leafPath.cubicTo(19.6247 * scale, 14.9341 * scale, 20.2408 * scale, 16.3896 * scale, 20.6107 * scale, 17.7984 * scale);
    leafPath.cubicTo(20.9604 * scale, 19.1306 * scale, 21.0756 * scale, 20.3725 * scale, 21.1143 * scale, 21.0496 * scale);
    leafPath.cubicTo(20.4371 * scale, 21.0109 * scale, 19.1944 * scale, 20.8968 * scale, 17.8618 * scale, 20.547 * scale);
    leafPath.cubicTo(16.4528 * scale, 20.1771 * scale, 14.9979 * scale, 19.5604 * scale, 13.9885 * scale, 18.5512 * scale);
    leafPath.cubicTo(12.9791 * scale, 17.5418 * scale, 12.3623 * scale, 16.0867 * scale, 11.9924 * scale, 14.6778 * scale);
    leafPath.cubicTo(11.6423 * scale, 13.3444 * scale, 11.5273 * scale, 12.1012 * scale, 11.4887 * scale, 11.4244 * scale);
    leafPath.cubicTo(12.1656 * scale, 11.4629 * scale, 13.4083 * scale, 11.5794 * scale, 14.7413 * scale, 11.9292 * scale);
    leafPath.cubicTo(16.1504 * scale, 12.299 * scale, 17.606 * scale, 12.9149 * scale, 18.6154 * scale, 13.9245 * scale);
    leafPath.close();

    canvas.drawPath(leafPath, paint);

    // Circle (globe)
    canvas.drawCircle(
      Offset(16 * scale, 16 * scale),
      11.5 * scale,
      paint,
    );
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
