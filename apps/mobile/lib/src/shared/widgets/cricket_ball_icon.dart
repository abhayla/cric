import 'package:flutter/material.dart';

/// A cricket ball icon rendered with CustomPaint.
///
/// Used in splash and login screens. The [size] parameter controls
/// the diameter of the ball (defaults to 72).
class CricketBallIcon extends StatelessWidget {
  const CricketBallIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CricketBallPainter(),
      ),
    );
  }
}

class _CricketBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Ball body
    final ballPaint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ballPaint);

    // Ball border
    final borderPaint = Paint()
      ..color = const Color(0xFFA01A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Seam lines
    final seamPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Left seam curve
    final leftSeam = Path()
      ..moveTo(size.width * 0.278, size.height * 0.25)
      ..cubicTo(
        size.width * 0.361,
        size.height * 0.389,
        size.width * 0.361,
        size.height * 0.611,
        size.width * 0.278,
        size.height * 0.75,
      );
    canvas.drawPath(leftSeam, seamPaint);

    // Right seam curve
    final rightSeam = Path()
      ..moveTo(size.width * 0.722, size.height * 0.25)
      ..cubicTo(
        size.width * 0.639,
        size.height * 0.389,
        size.width * 0.639,
        size.height * 0.611,
        size.width * 0.722,
        size.height * 0.75,
      );
    canvas.drawPath(rightSeam, seamPaint);

    // Stitch marks
    final stitchPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left stitches
    _drawStitch(canvas, stitchPaint, size, 0.25, 0.306, 0.306, 0.333);
    _drawStitch(canvas, stitchPaint, size, 0.236, 0.389, 0.292, 0.403);
    _drawStitch(canvas, stitchPaint, size, 0.236, 0.472, 0.292, 0.472);
    _drawStitch(canvas, stitchPaint, size, 0.236, 0.556, 0.292, 0.556);
    _drawStitch(canvas, stitchPaint, size, 0.25, 0.639, 0.306, 0.625);

    // Right stitches
    _drawStitch(canvas, stitchPaint, size, 0.75, 0.306, 0.694, 0.333);
    _drawStitch(canvas, stitchPaint, size, 0.764, 0.389, 0.708, 0.403);
    _drawStitch(canvas, stitchPaint, size, 0.764, 0.472, 0.708, 0.472);
    _drawStitch(canvas, stitchPaint, size, 0.764, 0.556, 0.708, 0.556);
    _drawStitch(canvas, stitchPaint, size, 0.75, 0.639, 0.694, 0.625);
  }

  void _drawStitch(
    Canvas canvas,
    Paint paint,
    Size size,
    double x1Frac,
    double y1Frac,
    double x2Frac,
    double y2Frac,
  ) {
    canvas.drawLine(
      Offset(size.width * x1Frac, size.height * y1Frac),
      Offset(size.width * x2Frac, size.height * y2Frac),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
