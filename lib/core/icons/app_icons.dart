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

/// Settings icon - gear (from Figma SVG)
class SettingsIconPainter extends CustomPainter {
  final Color color;

  SettingsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Gear outer path with teeth
    final gearPath = Path();

    // Top center tooth
    gearPath.moveTo(11.3682 * scale, 2 * scale);
    gearPath.lineTo(12.6318 * scale, 2 * scale);
    gearPath.cubicTo(12.8562 * scale, 2 * scale, 13.0002 * scale, 2.00033 * scale, 13.1108 * scale, 2.00777 * scale);
    gearPath.cubicTo(13.2164 * scale, 2.01487 * scale, 13.2579 * scale, 2.02693 * scale, 13.2791 * scale, 2.03529 * scale);
    gearPath.cubicTo(13.3909 * scale, 2.07958 * scale, 13.4834 * scale, 2.16326 * scale, 13.539 * scale, 2.27112 * scale);
    gearPath.cubicTo(13.5494 * scale, 2.29127 * scale, 13.5655 * scale, 2.33126 * scale, 13.583 * scale, 2.43549 * scale);
    gearPath.cubicTo(13.6013 * scale, 2.54465 * scale, 13.6159 * scale, 2.68779 * scale, 13.6382 * scale, 2.91101 * scale);
    gearPath.cubicTo(13.6784 * scale, 3.31309 * scale, 13.7111 * scale, 3.64429 * scale, 13.7574 * scale, 3.90175 * scale);
    gearPath.cubicTo(13.8029 * scale, 4.15434 * scale, 13.8727 * scale, 4.41118 * scale, 14.0331 * scale, 4.62154 * scale);
    gearPath.cubicTo(14.3599 * scale, 5.04993 * scale, 14.8918 * scale, 5.2705 * scale, 15.426 * scale, 5.19866 * scale);
    gearPath.cubicTo(15.6887 * scale, 5.16324 * scale, 15.9196 * scale, 5.0305 * scale, 16.13 * scale, 4.88402 * scale);
    gearPath.cubicTo(16.3444 * scale, 4.73472 * scale, 16.6017 * scale, 4.52356 * scale, 16.9142 * scale, 4.26787 * scale);
    gearPath.cubicTo(17.2861 * scale, 3.96368 * scale, 17.3696 * scale, 3.90738 * scale, 17.4381 * scale, 3.88551 * scale);
    gearPath.cubicTo(17.5531 * scale, 3.84884 * scale, 17.6775 * scale, 3.85505 * scale, 17.7886 * scale, 3.90316 * scale);
    gearPath.cubicTo(17.8095 * scale, 3.91222 * scale, 17.8474 * scale, 3.93307 * scale, 17.9272 * scale, 4.00272 * scale);
    gearPath.cubicTo(18.0106 * scale, 4.07562 * scale, 18.1127 * scale, 4.17728 * scale, 18.2714 * scale, 4.33598 * scale);
    gearPath.lineTo(19.164 * scale, 5.22855 * scale);
    gearPath.cubicTo(19.3227 * scale, 5.3872 * scale, 19.4243 * scale, 5.48937 * scale, 19.4973 * scale, 5.57283 * scale);
    gearPath.cubicTo(19.5669 * scale, 5.6526 * scale, 19.5878 * scale, 5.69054 * scale, 19.5969 * scale, 5.71147 * scale);
    gearPath.cubicTo(19.645 * scale, 5.82255 * scale, 19.6511 * scale, 5.94702 * scale, 19.6145 * scale, 6.06184 * scale);
    gearPath.cubicTo(19.6078 * scale, 6.08283 * scale, 19.591 * scale, 6.1223 * scale, 19.5293 * scale, 6.2087 * scale);
    gearPath.cubicTo(19.4648 * scale, 6.29912 * scale, 19.3736 * scale, 6.41074 * scale, 19.2313 * scale, 6.58466 * scale);
    gearPath.cubicTo(18.9753 * scale, 6.89732 * scale, 18.7645 * scale, 7.15454 * scale, 18.6153 * scale, 7.36931 * scale);
    gearPath.cubicTo(18.4688 * scale, 7.58009 * scale, 18.3369 * scale, 7.81073 * scale, 18.3014 * scale, 8.07247 * scale);
    gearPath.cubicTo(18.2293 * scale, 8.6073 * scale, 18.45 * scale, 9.13907 * scale, 18.8783 * scale, 9.46587 * scale);
    gearPath.cubicTo(19.0888 * scale, 9.6264 * scale, 19.3457 * scale, 9.6961 * scale, 19.5982 * scale, 9.7415 * scale);
    gearPath.cubicTo(19.8556 * scale, 9.7878 * scale, 20.1868 * scale, 9.8206 * scale, 20.5889 * scale, 9.8608 * scale);
    gearPath.cubicTo(21.0665 * scale, 9.9086 * scale, 21.1658 * scale, 9.9279 * scale, 21.2297 * scale, 9.9609 * scale);
    gearPath.cubicTo(21.3367 * scale, 10.0162 * scale, 21.4203 * scale, 10.1086 * scale, 21.4648 * scale, 10.2211 * scale);
    gearPath.cubicTo(21.4731 * scale, 10.2422 * scale, 21.4852 * scale, 10.2836 * scale, 21.4923 * scale, 10.3892 * scale);
    gearPath.cubicTo(21.4997 * scale, 10.4997 * scale, 21.5 * scale, 10.6437 * scale, 21.5 * scale, 10.8682 * scale);
    gearPath.lineTo(21.5 * scale, 13.1318 * scale);
    gearPath.cubicTo(21.5 * scale, 13.3561 * scale, 21.4997 * scale, 13.5002 * scale, 21.4922 * scale, 13.6107 * scale);
    gearPath.cubicTo(21.4851 * scale, 13.7164 * scale, 21.473 * scale, 13.758 * scale, 21.4647 * scale, 13.7791 * scale);
    gearPath.cubicTo(21.4204 * scale, 13.891 * scale, 21.3368 * scale, 13.9834 * scale, 21.2289 * scale, 14.039 * scale);
    gearPath.cubicTo(21.2087 * scale, 14.0494 * scale, 21.1688 * scale, 14.0654 * scale, 21.0645 * scale, 14.083 * scale);
    gearPath.cubicTo(20.9554 * scale, 14.1013 * scale, 20.8122 * scale, 14.1159 * scale, 20.589 * scale, 14.1382 * scale);
    gearPath.cubicTo(20.187 * scale, 14.1784 * scale, 19.856 * scale, 14.2111 * scale, 19.5987 * scale, 14.2575 * scale);
    gearPath.cubicTo(19.3462 * scale, 14.303 * scale, 19.0897 * scale, 14.3728 * scale, 18.8795 * scale, 14.533 * scale);
    gearPath.cubicTo(18.4507 * scale, 14.8599 * scale, 18.2303 * scale, 15.3917 * scale, 18.3023 * scale, 15.9262 * scale);
    gearPath.cubicTo(18.3377 * scale, 16.1882 * scale, 18.4698 * scale, 16.419 * scale, 18.6162 * scale, 16.6297 * scale);
    gearPath.cubicTo(18.7654 * scale, 16.8444 * scale, 18.9763 * scale, 17.1016 * scale, 19.2322 * scale, 17.4143 * scale);
    gearPath.cubicTo(19.3742 * scale, 17.5879 * scale, 19.4651 * scale, 17.6993 * scale, 19.5295 * scale, 17.7896 * scale);
    gearPath.cubicTo(19.5909 * scale, 17.8757 * scale, 19.6078 * scale, 17.9153 * scale, 19.6147 * scale, 17.9367 * scale);
    gearPath.cubicTo(19.6513 * scale, 18.0512 * scale, 19.6451 * scale, 18.1762 * scale, 19.5968 * scale, 18.2877 * scale);
    gearPath.cubicTo(19.5878 * scale, 18.3084 * scale, 19.5669 * scale, 18.3464 * scale, 19.4972 * scale, 18.4262 * scale);
    gearPath.cubicTo(19.4243 * scale, 18.5097 * scale, 19.3226 * scale, 18.6119 * scale, 19.164 * scale, 18.7705 * scale);
    gearPath.lineTo(18.2714 * scale, 19.663 * scale);
    gearPath.cubicTo(18.1127 * scale, 19.8217 * scale, 18.0106 * scale, 19.9234 * scale, 17.9272 * scale, 19.9963 * scale);
    gearPath.cubicTo(17.8474 * scale, 20.066 * scale, 17.8095 * scale, 20.0868 * scale, 17.7886 * scale, 20.0959 * scale);
    gearPath.cubicTo(17.6775 * scale, 20.144 * scale, 17.5531 * scale, 20.1502 * scale, 17.4381 * scale, 20.1135 * scale);
    gearPath.cubicTo(17.3696 * scale, 20.0916 * scale, 17.286 * scale, 20.0353 * scale, 16.9142 * scale, 19.7312 * scale);
    gearPath.cubicTo(16.6015 * scale, 19.4753 * scale, 16.344 * scale, 19.2641 * scale, 16.1293 * scale, 19.1147 * scale);
    gearPath.cubicTo(15.9186 * scale, 18.9682 * scale, 15.6875 * scale, 18.8356 * scale, 15.4249 * scale, 18.8003 * scale);
    gearPath.cubicTo(14.8909 * scale, 18.729 * scale, 14.3597 * scale, 18.9494 * scale, 14.0332 * scale, 19.3774 * scale);
    gearPath.cubicTo(13.8726 * scale, 19.5878 * scale, 13.8028 * scale, 19.8446 * scale, 13.7574 * scale, 20.0972 * scale);
    gearPath.cubicTo(13.7111 * scale, 20.3546 * scale, 13.6784 * scale, 20.6859 * scale, 13.6382 * scale, 21.088 * scale);
    gearPath.cubicTo(13.6159 * scale, 21.3114 * scale, 13.6013 * scale, 21.4548 * scale, 13.583 * scale, 21.5642 * scale);
    gearPath.cubicTo(13.5654 * scale, 21.6688 * scale, 13.5493 * scale, 21.7088 * scale, 13.5389 * scale, 21.729 * scale);
    gearPath.cubicTo(13.4834 * scale, 21.8367 * scale, 13.3908 * scale, 21.9205 * scale, 13.2789 * scale, 21.9648 * scale);
    gearPath.cubicTo(13.2579 * scale, 21.9731 * scale, 13.2164 * scale, 21.9852 * scale, 13.1105 * scale, 21.9923 * scale);
    gearPath.cubicTo(12.9997 * scale, 21.9997 * scale, 12.8554 * scale, 22 * scale, 12.6309 * scale, 22 * scale);
    gearPath.lineTo(11.3682 * scale, 22 * scale);
    gearPath.cubicTo(11.1437 * scale, 22 * scale, 10.9997 * scale, 21.9997 * scale, 10.8892 * scale, 21.9923 * scale);
    gearPath.cubicTo(10.7836 * scale, 21.9852 * scale, 10.7422 * scale, 21.9731 * scale, 10.721 * scale, 21.9647 * scale);
    gearPath.cubicTo(10.6086 * scale, 21.9203 * scale, 10.5162 * scale, 21.8367 * scale, 10.4608 * scale, 21.7295 * scale);
    gearPath.cubicTo(10.4279 * scale, 21.6658 * scale, 10.4086 * scale, 21.5665 * scale, 10.3608 * scale, 21.0889 * scale);
    gearPath.cubicTo(10.3206 * scale, 20.6868 * scale, 10.2878 * scale, 20.3556 * scale, 10.2415 * scale, 20.0982 * scale);
    gearPath.cubicTo(10.1961 * scale, 19.8457 * scale, 10.1264 * scale, 19.5888 * scale, 9.96594 * scale, 19.3784 * scale);
    gearPath.cubicTo(9.63907 * scale, 18.95 * scale, 9.1073 * scale, 18.7293 * scale, 8.57288 * scale, 18.8014 * scale);
    gearPath.cubicTo(8.31073 * scale, 18.8369 * scale, 8.08009 * scale, 18.9688 * scale, 7.86931 * scale, 19.1153 * scale);
    gearPath.cubicTo(7.65454 * scale, 19.2645 * scale, 7.39732 * scale, 19.4753 * scale, 7.08466 * scale, 19.7313 * scale);
    gearPath.cubicTo(6.91074 * scale, 19.8736 * scale, 6.79912 * scale, 19.9648 * scale, 6.7087 * scale, 20.0293 * scale);
    gearPath.cubicTo(6.6223 * scale, 20.091 * scale, 6.58283 * scale, 20.1078 * scale, 6.56162 * scale, 20.1146 * scale);
    gearPath.cubicTo(6.44702 * scale, 20.1511 * scale, 6.32255 * scale, 20.145 * scale, 6.2113 * scale, 20.0968 * scale);
    gearPath.cubicTo(6.19054 * scale, 20.0878 * scale, 6.1526 * scale, 20.0669 * scale, 6.07283 * scale, 19.9973 * scale);
    gearPath.cubicTo(5.98937 * scale, 19.9243 * scale, 5.8872 * scale, 19.8227 * scale, 5.72855 * scale, 19.664 * scale);
    gearPath.lineTo(4.83598 * scale, 18.7714 * scale);
    gearPath.cubicTo(4.67728 * scale, 18.6127 * scale, 4.57562 * scale, 18.5106 * scale, 4.50272 * scale, 18.4272 * scale);
    gearPath.cubicTo(4.43307 * scale, 18.3474 * scale, 4.41222 * scale, 18.3095 * scale, 4.40314 * scale, 18.2886 * scale);
    gearPath.cubicTo(4.35505 * scale, 18.1775 * scale, 4.34884 * scale, 18.0531 * scale, 4.38553 * scale, 17.9381 * scale);
    gearPath.cubicTo(4.40738 * scale, 17.8696 * scale, 4.46368 * scale, 17.7861 * scale, 4.76787 * scale, 17.4142 * scale);
    gearPath.cubicTo(5.02356 * scale, 17.1017 * scale, 5.23472 * scale, 16.8444 * scale, 5.38402 * scale, 16.63 * scale);
    gearPath.cubicTo(5.5305 * scale, 16.4196 * scale, 5.66324 * scale, 16.1887 * scale, 5.69864 * scale, 15.9262 * scale);
    gearPath.cubicTo(5.7705 * scale, 15.3918 * scale, 5.54993 * scale, 14.8599 * scale, 5.12167 * scale, 14.5332 * scale);
    gearPath.cubicTo(4.91118 * scale, 14.3727 * scale, 4.65434 * scale, 14.3029 * scale, 4.40175 * scale, 14.2574 * scale);
    gearPath.cubicTo(4.14429 * scale, 14.2111 * scale, 3.81309 * scale, 14.1784 * scale, 3.41101 * scale, 14.1382 * scale);
    gearPath.cubicTo(3.18779 * scale, 14.1159 * scale, 3.04465 * scale, 14.1013 * scale, 2.93549 * scale, 14.083 * scale);
    gearPath.cubicTo(2.83126 * scale, 14.0655 * scale, 2.79127 * scale, 14.0494 * scale, 2.77107 * scale, 14.039 * scale);
    gearPath.cubicTo(2.66326 * scale, 13.9834 * scale, 2.57958 * scale, 13.8909 * scale, 2.53522 * scale, 13.7789 * scale);
    gearPath.cubicTo(2.52693 * scale, 13.7579 * scale, 2.51487 * scale, 13.7164 * scale, 2.50777 * scale, 13.6108 * scale);
    gearPath.cubicTo(2.50033 * scale, 13.5002 * scale, 2.5 * scale, 13.3562 * scale, 2.5 * scale, 13.1318 * scale);
    gearPath.lineTo(2.5 * scale, 10.8682 * scale);
    gearPath.cubicTo(2.5 * scale, 10.6437 * scale, 2.50032 * scale, 10.4997 * scale, 2.50775 * scale, 10.3892 * scale);
    gearPath.cubicTo(2.51485 * scale, 10.2836 * scale, 2.5269 * scale, 10.2422 * scale, 2.53527 * scale, 10.221 * scale);
    gearPath.cubicTo(2.57974 * scale, 10.1086 * scale, 2.66329 * scale, 10.0162 * scale, 2.77054 * scale, 9.9608 * scale);
    gearPath.cubicTo(2.83421 * scale, 9.928 * scale, 2.93351 * scale, 9.9086 * scale, 3.41113 * scale, 9.8608 * scale);
    gearPath.cubicTo(3.81319 * scale, 9.8206 * scale, 4.14441 * scale, 9.7878 * scale, 4.40176 * scale, 9.7416 * scale);
    gearPath.cubicTo(4.65429 * scale, 9.6962 * scale, 4.91123 * scale, 9.6265 * scale, 5.12169 * scale, 9.46584 * scale);
    gearPath.cubicTo(5.54941 * scale, 9.13929 * scale, 5.77035 * scale, 8.60838 * scale, 5.69869 * scale, 8.07415 * scale);
    gearPath.cubicTo(5.66337 * scale, 7.81155 * scale, 5.53079 * scale, 7.58041 * scale, 5.38427 * scale, 7.3697 * scale);
    gearPath.cubicTo(5.23489 * scale, 7.15489 * scale, 5.02371 * scale, 6.89745 * scale, 4.76782 * scale, 6.58473 * scale);
    gearPath.cubicTo(4.62581 * scale, 6.41118 * scale, 4.53489 * scale, 6.29954 * scale, 4.47068 * scale, 6.20932 * scale);
    gearPath.cubicTo(4.40932 * scale, 6.12312 * scale, 4.39239 * scale, 6.08338 * scale, 4.38547 * scale, 6.06172 * scale);
    gearPath.cubicTo(4.34884 * scale, 5.94693 * scale, 4.35504 * scale, 5.82252 * scale, 4.40317 * scale, 5.71137 * scale);
    gearPath.cubicTo(4.4122 * scale, 5.69052 * scale, 4.43306 * scale, 5.65259 * scale, 4.50274 * scale, 5.57283 * scale);
    gearPath.cubicTo(4.57565 * scale, 5.48938 * scale, 4.67731 * scale, 5.38721 * scale, 4.83598 * scale, 5.22855 * scale);
    gearPath.lineTo(5.72855 * scale, 4.33598 * scale);
    gearPath.cubicTo(5.88722 * scale, 4.1773 * scale, 5.98938 * scale, 4.07564 * scale, 6.07283 * scale, 4.00273 * scale);
    gearPath.cubicTo(6.15258 * scale, 3.93306 * scale, 6.19051 * scale, 3.91221 * scale, 6.21145 * scale, 3.90314 * scale);
    gearPath.cubicTo(6.32248 * scale, 3.85504 * scale, 6.44685 * scale, 3.84882 * scale, 6.56191 * scale, 3.88553 * scale);
    gearPath.cubicTo(6.63033 * scale, 3.90737 * scale, 6.71406 * scale, 3.96383 * scale, 7.08578 * scale, 4.26788 * scale);
    gearPath.cubicTo(7.3984 * scale, 4.5236 * scale, 7.65564 * scale, 4.73456 * scale, 7.87024 * scale, 4.88374 * scale);
    gearPath.cubicTo(8.08083 * scale, 5.03014 * scale, 8.31172 * scale, 5.16245 * scale, 8.57405 * scale, 5.1977 * scale);
    gearPath.cubicTo(9.10841 * scale, 5.26941 * scale, 9.63931 * scale, 5.04861 * scale, 9.96584 * scale, 4.62071 * scale);
    gearPath.cubicTo(10.1263 * scale, 4.41028 * scale, 10.1961 * scale, 4.15368 * scale, 10.2415 * scale, 3.90123 * scale);
    gearPath.cubicTo(10.2878 * scale, 3.64403 * scale, 10.3206 * scale, 3.31305 * scale, 10.3608 * scale, 2.91114 * scale);
    gearPath.cubicTo(10.4086 * scale, 2.43355 * scale, 10.428 * scale, 2.33419 * scale, 10.4609 * scale, 2.27028 * scale);
    gearPath.cubicTo(10.5162 * scale, 2.16328 * scale, 10.6086 * scale, 2.07974 * scale, 10.721 * scale, 2.03525 * scale);
    gearPath.cubicTo(10.7421 * scale, 2.02691 * scale, 10.7836 * scale, 2.01486 * scale, 10.8892 * scale, 2.00776 * scale);
    gearPath.cubicTo(10.9997 * scale, 2.00032 * scale, 11.1437 * scale, 2 * scale, 11.3682 * scale, 2 * scale);
    gearPath.close();

    // Inner circle hole (center of gear) - draw as separate circle
    canvas.drawPath(gearPath, fillPaint);

    // Draw center circle (hole)
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(
      Offset(12 * scale, 12 * scale),
      4 * scale,
      centerPaint,
    );
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
