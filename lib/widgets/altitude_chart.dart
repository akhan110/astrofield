import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AltitudeChart extends StatelessWidget {
  const AltitudeChart({
    super.key,
    required this.peakAltitude,
    this.height = 190,
    this.accent = AppColors.primary,
  });

  final double height;
  final Color accent;
  final double peakAltitude;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _AltitudePainter(accent, peakAltitude.clamp(0, 90)),
      ),
    );
  }
}

class _AltitudePainter extends CustomPainter {
  _AltitudePainter(this.accent, this.peakAltitude);
  final Color accent;
  final double peakAltitude;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const top = 10.0;
    const bottom = 28.0;
    final width = size.width - left - 10;
    final height = size.height - top - bottom;
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 3; i++) {
      final y = top + height * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + width, y), grid);
      final label = '${90 - i * 30}°';
      textPainter.text = const TextSpan(
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10));
      textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: .26), accent.withValues(alpha: .02)],
      ).createShader(Rect.fromLTWH(left, top, width, height));

    final path = Path();
    final fill = Path();
    for (int i = 0; i <= 80; i++) {
      final t = i / 80;
      final normalized = math.sin(math.pi * t).clamp(0.0, 1.0).toDouble();
      final edgeAltitude = math.min(18.0, peakAltitude * .25);
      final altitude =
          edgeAltitude + normalized * (peakAltitude - edgeAltitude);
      final x = left + width * t;
      final y = top + height * (1 - altitude / 90);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, top + height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(left + width, top + height);
    fill.close();
    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);

    const times = ['6 PM', '9 PM', '12 AM', '3 AM', '6 AM'];
    for (int i = 0; i < times.length; i++) {
      final x = left + width * i / (times.length - 1);
      textPainter.text = TextSpan(
          text: times[i],
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10));
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, top + height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _AltitudePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.peakAltitude != peakAltitude;
}
