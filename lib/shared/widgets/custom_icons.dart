import 'package:flutter/material.dart';

/// Custom heart icon painter (like button)
class HeartIconPainter extends CustomPainter {
  final Color color;

  HeartIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Heart shape
    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.15, h * 0.55, w * 0.0, h * 0.35, w * 0.25, h * 0.15);
    path.cubicTo(w * 0.35, h * 0.05, w * 0.45, h * 0.1, w * 0.5, h * 0.25);
    path.cubicTo(w * 0.55, h * 0.1, w * 0.65, h * 0.05, w * 0.75, h * 0.15);
    path.cubicTo(w * 1.0, h * 0.35, w * 0.85, h * 0.55, w * 0.5, h * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom fire icon painter (super-like button)
class FireIconPainter extends CustomPainter {
  final Color color;

  FireIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Fire shape
    path.moveTo(w * 0.5, h * 0.0);
    path.cubicTo(w * 0.35, h * 0.15, w * 0.25, h * 0.25, w * 0.2, h * 0.45);
    path.cubicTo(w * 0.15, h * 0.55, w * 0.1, h * 0.7, w * 0.15, h * 0.8);
    path.cubicTo(w * 0.2, h * 0.9, w * 0.35, h * 1.0, w * 0.5, h * 1.0);
    path.cubicTo(w * 0.65, h * 1.0, w * 0.8, h * 0.9, w * 0.85, h * 0.8);
    path.cubicTo(w * 0.9, h * 0.7, w * 0.85, h * 0.55, w * 0.8, h * 0.45);
    path.cubicTo(w * 0.75, h * 0.25, w * 0.65, h * 0.15, w * 0.5, h * 0.0);
    path.close();

    // Inner flame
    final innerPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final innerPath = Path();
    innerPath.moveTo(w * 0.5, h * 0.35);
    innerPath.cubicTo(w * 0.4, h * 0.45, w * 0.35, h * 0.55, w * 0.35, h * 0.7);
    innerPath.cubicTo(w * 0.35, h * 0.85, w * 0.42, h * 0.95, w * 0.5, h * 0.95);
    innerPath.cubicTo(w * 0.58, h * 0.95, w * 0.65, h * 0.85, w * 0.65, h * 0.7);
    innerPath.cubicTo(w * 0.65, h * 0.55, w * 0.6, h * 0.45, w * 0.5, h * 0.35);
    innerPath.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom filter icon painter
class FilterIconPainter extends CustomPainter {
  final Color color;

  FilterIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Three horizontal lines with circles
    final y1 = h * 0.2;
    final y2 = h * 0.5;
    final y3 = h * 0.8;

    // Line 1 with circle on right
    canvas.drawLine(Offset(0, y1), Offset(w * 0.5, y1), paint);
    canvas.drawLine(Offset(w * 0.7, y1), Offset(w, y1), paint);
    canvas.drawCircle(Offset(w * 0.6, y1), w * 0.1, paint);

    // Line 2 with circle on left
    canvas.drawLine(Offset(0, y2), Offset(w * 0.2, y2), paint);
    canvas.drawLine(Offset(w * 0.4, y2), Offset(w, y2), paint);
    canvas.drawCircle(Offset(w * 0.3, y2), w * 0.1, paint);

    // Line 3 with circle on right
    canvas.drawLine(Offset(0, y3), Offset(w * 0.6, y3), paint);
    canvas.drawLine(Offset(w * 0.8, y3), Offset(w, y3), paint);
    canvas.drawCircle(Offset(w * 0.7, y3), w * 0.1, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom X (pass) icon painter
class XIconPainter extends CustomPainter {
  final Color color;

  XIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final padding = w * 0.15;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(w - padding, h - padding),
      paint,
    );
    canvas.drawLine(
      Offset(w - padding, padding),
      Offset(padding, h - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget wrapper for custom icons
class CustomIconWidget extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const CustomIconWidget({
    super.key,
    required this.painter,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: painter,
      size: Size(size, size),
    );
  }
}

/// Heart icon widget
class HeartIcon extends StatelessWidget {
  final Color color;
  final double size;

  const HeartIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      painter: HeartIconPainter(color: color),
      size: size,
    );
  }
}

/// Fire icon widget
class FireIcon extends StatelessWidget {
  final Color color;
  final double size;

  const FireIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      painter: FireIconPainter(color: color),
      size: size,
    );
  }
}

/// Filter icon widget
class FilterIcon extends StatelessWidget {
  final Color color;
  final double size;

  const FilterIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      painter: FilterIconPainter(color: color),
      size: size,
    );
  }
}

/// X icon widget
class XIcon extends StatelessWidget {
  final Color color;
  final double size;

  const XIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      painter: XIconPainter(color: color),
      size: size,
    );
  }
}
