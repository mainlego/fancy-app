import 'package:flutter/material.dart';

/// Custom icon painters for the app
/// Based on Figma SVG icons

/// Home icon - circle with leaf (discover/swipe)
class HomeIconPainter extends CustomPainter {
  final Color color;

  HomeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer circle (r=8.5, cx=12, cy=12)
    canvas.drawCircle(
      Offset(12 * scale, 12 * scale),
      8.5 * scale,
      paint,
    );

    // Leaf path
    final leafPath = Path();
    leafPath.moveTo(13.6473 * scale, 10.3531 * scale);
    leafPath.cubicTo(
      14.3553 * scale, 11.0615 * scale,
      14.8042 * scale, 12.0791 * scale,
      15.0822 * scale, 13.0925 * scale,
    );
    leafPath.cubicTo(
      15.3403 * scale, 14.0334 * scale,
      15.438 * scale, 14.9278 * scale,
      15.4758 * scale, 15.4734 * scale,
    );
    leafPath.cubicTo(
      14.9302 * scale, 15.4357 * scale,
      14.035 * scale, 15.3392 * scale,
      13.0932 * scale, 15.0809 * scale,
    );
    leafPath.cubicTo(
      12.0796 * scale, 14.8029 * scale,
      11.0617 * scale, 14.3544 * scale,
      10.3535 * scale, 13.6462 * scale,
    );
    leafPath.cubicTo(
      9.64535 * scale, 12.9381 * scale,
      9.19661 * scale, 11.9203 * scale,
      8.91855 * scale, 10.9069 * scale,
    );
    leafPath.cubicTo(
      8.66013 * scale, 9.96483 * scale,
      8.56257 * scale, 9.0692 * scale,
      8.52481 * scale, 8.52373 * scale,
    );
    leafPath.cubicTo(
      9.07039 * scale, 8.56141 * scale,
      9.96538 * scale, 8.65938 * scale,
      10.9071 * scale, 8.91757 * scale,
    );
    leafPath.cubicTo(
      11.9208 * scale, 9.1955 * scale,
      12.939 * scale, 9.64469 * scale,
      13.6473 * scale, 10.3531 * scale,
    );
    leafPath.close();

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chats icon - house with envelope shape
class ChatsIconPainter extends CustomPainter {
  final Color color;

  ChatsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Main house shape
    final housePath = Path();
    housePath.moveTo(4 * scale, 10.4721 * scale);
    housePath.cubicTo(
      4 * scale, 9.26932 * scale,
      4 * scale, 8.66791 * scale,
      4.2987 * scale, 8.18461 * scale,
    );
    housePath.cubicTo(
      4.5974 * scale, 7.7013 * scale,
      5.13531 * scale, 7.43234 * scale,
      6.21115 * scale, 6.89443 * scale,
    );
    housePath.lineTo(10.2111 * scale, 4.89443 * scale);
    housePath.cubicTo(
      11.089 * scale, 4.45552 * scale,
      11.5279 * scale, 4.23607 * scale,
      12 * scale, 4.23607 * scale,
    );
    housePath.cubicTo(
      12.4721 * scale, 4.23607 * scale,
      12.911 * scale, 4.45552 * scale,
      13.7889 * scale, 4.89443 * scale,
    );
    housePath.lineTo(17.7889 * scale, 6.89443 * scale);
    housePath.cubicTo(
      18.8647 * scale, 7.43234 * scale,
      19.4026 * scale, 7.7013 * scale,
      19.7013 * scale, 8.18461 * scale,
    );
    housePath.cubicTo(
      20 * scale, 8.66791 * scale,
      20 * scale, 9.26932 * scale,
      20 * scale, 10.4721 * scale,
    );
    housePath.lineTo(20 * scale, 16 * scale);
    housePath.cubicTo(
      20 * scale, 17.8856 * scale,
      20 * scale, 18.8284 * scale,
      19.4142 * scale, 19.4142 * scale,
    );
    housePath.cubicTo(
      18.8284 * scale, 20 * scale,
      17.8856 * scale, 20 * scale,
      16 * scale, 20 * scale,
    );
    housePath.lineTo(8 * scale, 20 * scale);
    housePath.cubicTo(
      6.11438 * scale, 20 * scale,
      5.17157 * scale, 20 * scale,
      4.58579 * scale, 19.4142 * scale,
    );
    housePath.cubicTo(
      4 * scale, 18.8284 * scale,
      4 * scale, 17.8856 * scale,
      4 * scale, 16 * scale,
    );
    housePath.lineTo(4 * scale, 10.4721 * scale);
    housePath.close();

    canvas.drawPath(housePath, paint);

    // Envelope/mail line
    final envelopePath = Path();
    envelopePath.moveTo(4 * scale, 10 * scale);
    envelopePath.lineTo(6.41421 * scale, 12.4142 * scale);
    envelopePath.cubicTo(
      6.78929 * scale, 12.7893 * scale,
      7.29799 * scale, 13 * scale,
      7.82843 * scale, 13 * scale,
    );
    envelopePath.lineTo(16.1716 * scale, 13 * scale);
    envelopePath.cubicTo(
      16.702 * scale, 13 * scale,
      17.2107 * scale, 12.7893 * scale,
      17.5858 * scale, 12.4142 * scale,
    );
    envelopePath.lineTo(20 * scale, 10 * scale);

    canvas.drawPath(envelopePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Profile icon - user in rounded square
class ProfileIconPainter extends CustomPainter {
  final Color color;

  ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Body/shoulders arc
    final bodyPath = Path();
    bodyPath.moveTo(17.9334 * scale, 21.2571 * scale);
    bodyPath.cubicTo(
      17.7171 * scale, 20.0575 * scale,
      16.9849 * scale, 18.9644 * scale,
      15.8732 * scale, 18.1813 * scale,
    );
    bodyPath.cubicTo(
      14.7615 * scale, 17.3983 * scale,
      13.346 * scale, 16.9787 * scale,
      11.8906 * scale, 17.0008 * scale,
    );
    bodyPath.cubicTo(
      10.4352 * scale, 17.0229 * scale,
      9.0391 * scale, 17.4852 * scale,
      7.96236 * scale, 18.3015 * scale,
    );
    bodyPath.cubicTo(
      6.88562 * scale, 19.1178 * scale,
      6.20171 * scale, 20.2325 * scale,
      6.03804 * scale, 21.4378 * scale,
    );

    canvas.drawPath(bodyPath, paint);

    // Head circle (cx=12, cy=10, r=3)
    canvas.drawCircle(
      Offset(12 * scale, 10 * scale),
      3 * scale,
      paint,
    );

    // Rounded rectangle border (2.5, 2.5, 19x19, rx=3.5)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.5 * scale, 2.5 * scale, 19 * scale, 19 * scale),
      Radius.circular(3.5 * scale),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Settings icon - gear
class SettingsIconPainter extends CustomPainter {
  final Color color;

  SettingsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw outer circle
    canvas.drawCircle(
      Offset(12 * scale, 12 * scale),
      9 * scale,
      strokePaint,
    );

    // Draw inner circle
    canvas.drawCircle(
      Offset(12 * scale, 12 * scale),
      4 * scale,
      strokePaint,
    );

    // Draw gear teeth lines
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      final innerRadius = 5.5 * scale;
      final outerRadius = 8 * scale;

      final startX = 12 * scale + innerRadius * cos(angle);
      final startY = 12 * scale + innerRadius * sin(angle);
      final endX = 12 * scale + outerRadius * cos(angle);
      final endY = 12 * scale + outerRadius * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        strokePaint,
      );
    }
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  static double _cos(double x) {
    return 1 - x*x/2 + x*x*x*x/24 - x*x*x*x*x*x/720;
  }

  static double _sin(double x) {
    return x - x*x*x/6 + x*x*x*x*x/120 - x*x*x*x*x*x*x/5040;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Close icon - X mark
class CloseIconPainter extends CustomPainter {
  final Color color;

  CloseIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Line 1: from (18,6) to (6,18)
    canvas.drawLine(
      Offset(18 * scale, 6 * scale),
      Offset(6 * scale, 18 * scale),
      paint,
    );

    // Line 2: from (6,6) to (18,18)
    canvas.drawLine(
      Offset(6 * scale, 6 * scale),
      Offset(18 * scale, 18 * scale),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Back arrow icon
class BackArrowIconPainter extends CustomPainter {
  final Color color;

  BackArrowIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Arrow head and body
    path.moveTo(4 * scale, 10 * scale);
    path.lineTo(9 * scale, 5 * scale);
    path.lineTo(9 * scale, 9.5 * scale);
    path.lineTo(14 * scale, 9.5 * scale);
    path.cubicTo(
      17.0376 * scale, 9.5 * scale,
      19.5 * scale, 12 * scale,
      19.5 * scale, 16 * scale,
    );
    path.lineTo(19.5 * scale, 18 * scale);
    path.lineTo(20.5 * scale, 18 * scale);
    path.lineTo(20.5 * scale, 16 * scale);
    path.cubicTo(
      20.5 * scale, 12.4101 * scale,
      17.5898 * scale, 9.5 * scale,
      14 * scale, 9.5 * scale,
    );
    path.lineTo(14 * scale, 10.5 * scale);
    path.lineTo(4 * scale, 10.5 * scale);
    path.lineTo(4 * scale, 10 * scale);
    path.close();

    // Simplified arrow
    final arrowPath = Path();
    arrowPath.moveTo(4 * scale, 10 * scale);
    arrowPath.lineTo(9 * scale, 5 * scale);
    arrowPath.lineTo(9 * scale, 10 * scale);
    arrowPath.lineTo(14 * scale, 10 * scale);
    arrowPath.quadraticBezierTo(
      20 * scale, 10 * scale,
      20 * scale, 16 * scale,
    );
    arrowPath.lineTo(20 * scale, 18 * scale);
    arrowPath.lineTo(19.5 * scale, 18 * scale);
    arrowPath.lineTo(19.5 * scale, 16 * scale);
    arrowPath.quadraticBezierTo(
      19.5 * scale, 10.5 * scale,
      14 * scale, 10.5 * scale,
    );
    arrowPath.lineTo(9 * scale, 10.5 * scale);
    arrowPath.lineTo(9 * scale, 15 * scale);
    arrowPath.close();

    canvas.drawPath(arrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Lock icon - for locked content
class LockIconPainter extends CustomPainter {
  final Color color;

  LockIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Lock keyhole circle
    canvas.drawCircle(
      Offset(12 * scale, 15 * scale),
      2 * scale,
      fillPaint,
    );

    // Lock body (rounded rectangle)
    final bodyPath = Path();
    bodyPath.moveTo(4.5 * scale, 13.5 * scale);
    bodyPath.cubicTo(
      4.5 * scale, 11.6144 * scale,
      4.5 * scale, 10.6716 * scale,
      5.08579 * scale, 10.0858 * scale,
    );
    bodyPath.cubicTo(
      5.67157 * scale, 9.5 * scale,
      6.61438 * scale, 9.5 * scale,
      8.5 * scale, 9.5 * scale,
    );
    bodyPath.lineTo(15.5 * scale, 9.5 * scale);
    bodyPath.cubicTo(
      17.3856 * scale, 9.5 * scale,
      18.3284 * scale, 9.5 * scale,
      18.9142 * scale, 10.0858 * scale,
    );
    bodyPath.cubicTo(
      19.5 * scale, 10.6716 * scale,
      19.5 * scale, 11.6144 * scale,
      19.5 * scale, 13.5 * scale,
    );
    bodyPath.lineTo(19.5 * scale, 14.5 * scale);
    bodyPath.cubicTo(
      19.5 * scale, 17.3284 * scale,
      19.5 * scale, 18.7426 * scale,
      18.6213 * scale, 19.6213 * scale,
    );
    bodyPath.cubicTo(
      17.7426 * scale, 20.5 * scale,
      16.3284 * scale, 20.5 * scale,
      13.5 * scale, 20.5 * scale,
    );
    bodyPath.lineTo(10.5 * scale, 20.5 * scale);
    bodyPath.cubicTo(
      7.67157 * scale, 20.5 * scale,
      6.25736 * scale, 20.5 * scale,
      5.37868 * scale, 19.6213 * scale,
    );
    bodyPath.cubicTo(
      4.5 * scale, 18.7426 * scale,
      4.5 * scale, 17.3284 * scale,
      4.5 * scale, 14.5 * scale,
    );
    bodyPath.lineTo(4.5 * scale, 13.5 * scale);
    bodyPath.close();

    canvas.drawPath(bodyPath, strokePaint);

    // Lock shackle (top arc)
    final shacklePath = Path();
    shacklePath.moveTo(16.5 * scale, 9.5 * scale);
    shacklePath.lineTo(16.5 * scale, 8 * scale);
    shacklePath.cubicTo(
      16.5 * scale, 5.51472 * scale,
      14.4853 * scale, 3.5 * scale,
      12 * scale, 3.5 * scale,
    );
    shacklePath.cubicTo(
      9.51472 * scale, 3.5 * scale,
      7.5 * scale, 5.51472 * scale,
      7.5 * scale, 8 * scale,
    );
    shacklePath.lineTo(7.5 * scale, 9.5 * scale);

    canvas.drawPath(shacklePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Edit/Pencil icon
class EditIconPainter extends CustomPainter {
  final Color color;

  EditIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Pencil body outline
    final pencilPath = Path();
    pencilPath.moveTo(15 * scale, 5.91406 * scale);
    pencilPath.cubicTo(
      15.3604 * scale, 5.91406 * scale,
      15.6531 * scale, 6.066 * scale,
      15.916 * scale, 6.2666 * scale,
    );
    pencilPath.cubicTo(
      16.1673 * scale, 6.45837 * scale,
      16.4444 * scale, 6.73733 * scale,
      16.7676 * scale, 7.06055 * scale,
    );
    pencilPath.lineTo(16.9395 * scale, 7.23242 * scale);
    pencilPath.cubicTo(
      17.2627 * scale, 7.55564 * scale,
      17.5416 * scale, 7.83268 * scale,
      17.7334 * scale, 8.08398 * scale,
    );
    pencilPath.cubicTo(
      17.934 * scale, 8.3469 * scale,
      18.0859 * scale, 8.63961 * scale,
      18.0859 * scale, 9 * scale,
    );
    pencilPath.cubicTo(
      18.0859 * scale, 9.36038 * scale,
      17.934 * scale, 9.6531 * scale,
      17.7334 * scale, 9.91602 * scale,
    );
    pencilPath.cubicTo(
      17.5416 * scale, 10.1673 * scale,
      17.2627 * scale, 10.4444 * scale,
      16.9395 * scale, 10.7676 * scale,
    );
    pencilPath.lineTo(9.74512 * scale, 17.9619 * scale);
    pencilPath.cubicTo(
      9.56928 * scale, 18.1377 * scale,
      9.4185 * scale, 18.2942 * scale,
      9.22754 * scale, 18.4023 * scale,
    );
    pencilPath.cubicTo(
      9.03664 * scale, 18.5104 * scale,
      8.82512 * scale, 18.5589 * scale,
      8.58398 * scale, 18.6191 * scale,
    );
    pencilPath.lineTo(5.92969 * scale, 19.2832 * scale);
    pencilPath.cubicTo(
      5.7655 * scale, 19.3242 * scale,
      5.587 * scale, 19.3702 * scale,
      5.43848 * scale, 19.3848 * scale,
    );
    pencilPath.cubicTo(
      5.28375 * scale, 19.3999 * scale,
      5.02289 * scale, 19.3959 * scale,
      4.81348 * scale, 19.1865 * scale,
    );
    pencilPath.cubicTo(
      4.60407 * scale, 18.9771 * scale,
      4.6001 * scale, 18.7163 * scale,
      4.61523 * scale, 18.5615 * scale,
    );
    pencilPath.cubicTo(
      4.62976 * scale, 18.413 * scale,
      4.67575 * scale, 18.2345 * scale,
      4.7168 * scale, 18.0703 * scale,
    );
    pencilPath.lineTo(5.38086 * scale, 15.416 * scale);
    pencilPath.cubicTo(
      5.44114 * scale, 15.1749 * scale,
      5.48962 * scale, 14.9634 * scale,
      5.59766 * scale, 14.7725 * scale,
    );
    pencilPath.cubicTo(
      5.70578 * scale, 14.5815 * scale,
      5.86225 * scale, 14.4307 * scale,
      6.03809 * scale, 14.2549 * scale,
    );
    pencilPath.lineTo(13.2324 * scale, 7.06055 * scale);
    pencilPath.cubicTo(
      13.5556 * scale, 6.73733 * scale,
      13.8327 * scale, 6.45837 * scale,
      14.084 * scale, 6.2666 * scale,
    );
    pencilPath.cubicTo(
      14.3469 * scale, 6.066 * scale,
      14.6396 * scale, 5.91406 * scale,
      15 * scale, 5.91406 * scale,
    );
    pencilPath.close();

    canvas.drawPath(pencilPath, strokePaint);

    // Pencil tip fill
    final tipPath = Path();
    tipPath.moveTo(12.5 * scale, 7.5 * scale);
    tipPath.lineTo(15.5 * scale, 5.5 * scale);
    tipPath.lineTo(18.5 * scale, 8.5 * scale);
    tipPath.lineTo(16.5 * scale, 11.5 * scale);
    tipPath.close();

    canvas.drawPath(tipPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Play/Video icon
class PlayIconPainter extends CustomPainter {
  final Color color;

  PlayIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer circle
    canvas.drawCircle(
      Offset(12 * scale, 12 * scale),
      9 * scale,
      strokePaint,
    );

    // Play triangle
    final playPath = Path();
    playPath.moveTo(16.2111 * scale, 11.1056 * scale);
    playPath.lineTo(9.73666 * scale, 7.86833 * scale);
    playPath.cubicTo(
      8.93878 * scale, 7.46939 * scale,
      8 * scale, 8.04958 * scale,
      8 * scale, 8.94164 * scale,
    );
    playPath.lineTo(8 * scale, 15.0584 * scale);
    playPath.cubicTo(
      8 * scale, 15.9504 * scale,
      8.93878 * scale, 16.5306 * scale,
      9.73666 * scale, 16.1317 * scale,
    );
    playPath.lineTo(16.2111 * scale, 12.8944 * scale);
    playPath.cubicTo(
      16.9482 * scale, 12.5259 * scale,
      16.9482 * scale, 11.4741 * scale,
      16.2111 * scale, 11.1056 * scale,
    );
    playPath.close();

    canvas.drawPath(playPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Check/Checkmark in circle icon
class CheckCircleIconPainter extends CustomPainter {
  final Color color;

  CheckCircleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer circle
    canvas.drawCircle(
      Offset(12 * scale, 12 * scale),
      9 * scale,
      strokePaint,
    );

    // Checkmark
    final checkPath = Path();
    checkPath.moveTo(8 * scale, 12 * scale);
    checkPath.lineTo(11 * scale, 15 * scale);
    checkPath.lineTo(16 * scale, 9 * scale);

    canvas.drawPath(checkPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Add/Plus in square icon
class AddSquareIconPainter extends CustomPainter {
  final Color color;

  AddSquareIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round;

    // Rounded square
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5 * scale, 3.5 * scale, 17 * scale, 17 * scale),
      Radius.circular(3.5 * scale),
    );
    canvas.drawRRect(rrect, strokePaint);

    // Vertical line
    canvas.drawLine(
      Offset(12 * scale, 8 * scale),
      Offset(12 * scale, 16 * scale),
      strokePaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(8 * scale, 12 * scale),
      Offset(16 * scale, 12 * scale),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gallery/Photo library icon
class GalleryIconPainter extends CustomPainter {
  final Color color;

  GalleryIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Rounded rectangle frame
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.5 * scale, 2.5 * scale, 19 * scale, 19 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(rrect, strokePaint);

    // Mountain/landscape path
    final mountainPath = Path();
    mountainPath.moveTo(2.5 * scale, 14.4999 * scale);
    mountainPath.lineTo(5.8055 * scale, 11.1945 * scale);
    mountainPath.cubicTo(
      6.68783 * scale, 10.3122 * scale,
      8.15379 * scale, 10.4443 * scale,
      8.86406 * scale, 11.4702 * scale,
    );
    mountainPath.lineTo(10.7664 * scale, 14.218 * scale);
    mountainPath.cubicTo(
      11.4311 * scale, 15.1781 * scale,
      12.7735 * scale, 15.3669 * scale,
      13.6773 * scale, 14.6275 * scale,
    );
    mountainPath.lineTo(16.0992 * scale, 12.646 * scale);
    mountainPath.cubicTo(
      16.8944 * scale, 11.9954 * scale,
      18.0533 * scale, 12.0532 * scale,
      18.7798 * scale, 12.7797 * scale,
    );
    mountainPath.lineTo(21.5 * scale, 15.4999 * scale);

    canvas.drawPath(mountainPath, strokePaint);

    // Sun circle
    canvas.drawCircle(
      Offset(16.5 * scale, 7.5 * scale),
      1.5 * scale,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget helper for using icon painters
class AppIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const AppIcon({
    super.key,
    required this.painter,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: painter,
    );
  }
}
