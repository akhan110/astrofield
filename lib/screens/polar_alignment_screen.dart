import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geoengine/geoengine.dart' as astro;
import 'package:get/get.dart';
import '../controllers/field_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class PolarAlignmentScreen extends StatefulWidget {
  const PolarAlignmentScreen({super.key});

  @override
  State<PolarAlignmentScreen> createState() => _PolarAlignmentScreenState();
}

class _PolarAlignmentScreenState extends State<PolarAlignmentScreen> {
  late DateTime time;
  bool isLive = true;
  bool invertedView = false;
  late bool isNorthern;

  @override
  void initState() {
    super.initState();
    final c = Get.find<FieldController>();
    time = c.time.value;
    isNorthern = (c.site.value?.latitude ?? 45.0) >= 0;
  }

  double get lstHours {
    final c = Get.find<FieldController>();
    final site = c.site.value;
    final lon = site?.longitude ?? 0.0;
    final gst = astro.siderealTime(time.toUtc());
    var lst = (gst + lon / 15.0) % 24.0;
    if (lst < 0) lst += 24.0;
    return lst;
  }

  astro.EquatorialCoordinates _getPoleStarCoordinates() {
    final c = Get.find<FieldController>();
    final site = c.site.value;
    final observer = astro.Observer(
      site?.latitude ?? (isNorthern ? 45.0 : -45.0),
      site?.longitude ?? 0.0,
      site?.elevation ?? 0.0,
    );

    if (isNorthern) {
      // Polaris J2000
      astro.defineStar(astro.Body.Star1, 2.5303, 89.2641, 1000000);
    } else {
      // Sigma Octantis J2000
      astro.defineStar(astro.Body.Star1, 21.146, -88.956, 1000000);
    }
    return astro.equator(astro.Body.Star1, time.toUtc(), observer, true, true);
  }

  astro.HorizontalCoordinates _getPoleStarHorizon() {
    final c = Get.find<FieldController>();
    final site = c.site.value;
    final observer = astro.Observer(
      site?.latitude ?? (isNorthern ? 45.0 : -45.0),
      site?.longitude ?? 0.0,
      site?.elevation ?? 0.0,
    );
    final eq = _getPoleStarCoordinates();
    return astro.HorizontalCoordinates.horizon(
      time.toUtc(),
      observer,
      eq.ra,
      eq.dec,
    );
  }

  double get hourAngleHours {
    final eq = _getPoleStarCoordinates();
    var ha = (lstHours - eq.ra) % 24.0;
    if (ha < 0) ha += 24.0;
    return ha;
  }

  double get reticleAngleDegrees {
    // Hour angle converted to degrees on reticle clock
    // 0h = 12 o'clock (top), 6h = 3 o'clock (right/west), 12h = 6 o'clock (bottom), 18h = 9 o'clock (left/east)
    var angle = hourAngleHours * 15.0;
    if (invertedView) {
      angle = (angle + 180.0) % 360.0;
    }
    return angle;
  }

  String _formatHms(double hours) {
    final h = hours.floor();
    final remM = (hours - h) * 60;
    final m = remM.floor();
    final s = ((remM - m) * 60).round();
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String get clockPositionText {
    // Convert 24-hour hour angle into 12-hour clock face position
    final clockHours = (hourAngleHours / 2.0) % 12.0;
    final h = clockHours.floor() == 0 ? 12 : clockHours.floor();
    final m = ((clockHours - clockHours.floor()) * 60).round();
    return '$h:${m.toString().padLeft(2, '0')} o\'clock';
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();
    final site = c.site.value;
    final lat = site?.latitude ?? (isNorthern ? 45.0 : -45.0);
    final eq = _getPoleStarCoordinates();
    final horiz = _getPoleStarHorizon();
    final polarDistArcmin = (90.0 - eq.dec.abs()) * 60.0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            PageHeader(
              title: 'Polar Alignment Clock',
              subtitle: 'Hour angle reticle for equatorial mounts',
              trailing: IconButton(
                tooltip: 'Return to live',
                icon: Icon(
                  Icons.restore_rounded,
                  color: isLive ? AppColors.secondary : AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    isLive = true;
                    time = DateTime.now().toUtc();
                  });
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hemisphere & Inversion Controls
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('North (Polaris)'),
                              icon: Icon(Icons.north_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('South (Octans)'),
                              icon: Icon(Icons.south_rounded, size: 16),
                            ),
                          ],
                          selected: {isNorthern},
                          onSelectionChanged: (val) {
                            setState(() => isNorthern = val.first);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // View Mode Toggle (Normal vs Inverted Optical Finder)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            invertedView
                                ? Icons.flip_camera_android_rounded
                                : Icons.remove_red_eye_outlined,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            invertedView
                                ? 'Inverted View (Optical Scope)'
                                : 'Direct View (Erect / Reticle)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: invertedView,
                        onChanged: (v) => setState(() => invertedView = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Interactive Polar Scope Reticle
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isNorthern
                                  ? 'Polaris HA: ${_formatHms(hourAngleHours)}'
                                  : 'Sigma Octantis HA: ${_formatHms(hourAngleHours)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                clockPositionText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Canvas Reticle
                        SizedBox(
                          height: 310,
                          child: CustomPaint(
                            size: const Size(double.infinity, 310),
                            painter: _PolarReticlePainter(
                              isNorthern: isNorthern,
                              hourAngleDeg: reticleAngleDegrees,
                              invertedView: invertedView,
                              polarDistanceArcmin: polarDistArcmin,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Legend / Tip below reticle
                        Text(
                          isNorthern
                              ? 'Place Polaris inside the highlighted circle on your mount’s reticle.'
                              : 'Align the Octans Trapezoid with the 4 guide stars in your polar finder.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Mount Settings & Coordinates
                  const Text(
                    'Mount Alignment Readings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  AppCard(
                    child: Column(
                      children: [
                        _dataRow(
                          'Mount Latitude Wedge',
                          '${lat.abs().toStringAsFixed(2)}° ${lat >= 0 ? "N" : "S"}',
                          'Set your mount’s altitude knob to this value',
                          AppColors.secondary,
                        ),
                        const Divider(height: 18, color: AppColors.border),
                        _dataRow(
                          'Hour Angle (HA)',
                          _formatHms(hourAngleHours),
                          'Angle: ${hourAngleHours.toStringAsFixed(2)}h (${(hourAngleHours * 15).toStringAsFixed(1)}°)',
                          AppColors.primary,
                        ),
                        const Divider(height: 18, color: AppColors.border),
                        _dataRow(
                          'Local Sidereal Time (LST)',
                          _formatHms(lstHours),
                          'Longitude: ${(site?.longitude ?? 0.0).toStringAsFixed(2)}°',
                          AppColors.violet,
                        ),
                        const Divider(height: 18, color: AppColors.border),
                        _dataRow(
                          isNorthern ? 'Polaris Altitude' : 'Sigma Oct Altitude',
                          '${horiz.altitude.toStringAsFixed(2)}°',
                          'Azimuth: ${horiz.azimuth.toStringAsFixed(1)}°',
                          AppColors.amber,
                        ),
                        const Divider(height: 18, color: AppColors.border),
                        _dataRow(
                          'Pole Offset Distance',
                          '${polarDistArcmin.toStringAsFixed(1)} arcmin',
                          'True celestial pole offset',
                          AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Step-by-Step Alignment Guide Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: AppColors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'How to Align Your Mount',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _stepRow(
                          '1',
                          'Level your tripod carefully using a spirit bubble. Point the polar axis roughly towards ${isNorthern ? "True North" : "True South"}.',
                        ),
                        _stepRow(
                          '2',
                          'Adjust your mount altitude wedge so the scale reads exactly ${lat.abs().toStringAsFixed(1)}°.',
                        ),
                        _stepRow(
                          '3',
                          'Look into your polar scope. Use the altitude & azimuth fine-tune knobs to place ${isNorthern ? "Polaris" : "Sigma Octantis"} on the reticle circle at $clockPositionText.',
                        ),
                        _stepRow(
                          '4',
                          'Lock the mount clutches. Your tracking is now aligned for pinpoint long-exposure astrophotography!',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Time Simulation Slider
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Simulate Time Tonight',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isLive = true;
                                  time = DateTime.now().toUtc();
                                });
                              },
                              child: Text(isLive ? 'Live' : 'Reset to Now'),
                            ),
                          ],
                        ),
                        Text(
                          'Simulating: ${_formatDateTime(time.toLocal())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Slider(
                          value: time.hour + time.minute / 60.0,
                          min: 0.0,
                          max: 23.9,
                          divisions: 96,
                          label:
                              '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}',
                          onChanged: (val) {
                            final h = val.floor();
                            final m = ((val - h) * 60).round();
                            final local = time.toLocal();
                            setState(() {
                              isLive = false;
                              time = DateTime(
                                local.year,
                                local.month,
                                local.day,
                                h,
                                m,
                              ).toUtc();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}  $h12:${dt.minute.toString().padLeft(2, "0")} $period';
  }

  static Widget _dataRow(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  static Widget _stepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolarReticlePainter extends CustomPainter {
  _PolarReticlePainter({
    required this.isNorthern,
    required this.hourAngleDeg,
    required this.invertedView,
    required this.polarDistanceArcmin,
  });

  final bool isNorthern;
  final double hourAngleDeg;
  final bool invertedView;
  final double polarDistanceArcmin;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.46;

    // Dark sky backdrop
    final bgPaint = Paint()..color = const Color(0xFF060913);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Reticle circular bowl
    final bowlPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF131D33),
          Color(0xFF060913),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, bowlPaint);

    final reticleBorder = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, maxR, reticleBorder);

    // Crosshairs
    final crossPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx - maxR, center.dy), Offset(center.dx + maxR, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxR), Offset(center.dx, center.dy + maxR), crossPaint);

    // Center Celestial Pole Marker
    final poleCross = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), poleCross);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), poleCross);

    // Reticle ring representing Polaris/Octans drift radius (~37-40 arcmin)
    // Scale: Polaris circle is at ~55% of max radius
    final polarisRadius = maxR * 0.58;

    // Epoch circles for polar drift: 2020, 2024, 2028, 2032
    for (var i = -2; i <= 2; i++) {
      final r = polarisRadius + i * 5.0;
      final epochPaint = Paint()
        ..color = i == 0
            ? AppColors.primary.withValues(alpha: 0.6)
            : AppColors.border.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.4 : 0.7;
      canvas.drawCircle(center, r, epochPaint);
    }

    // 24 Hour ticks and 12-Hour Clock Numbers
    final tickPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.8)
      ..strokeWidth = 1.0;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var h = 0; h < 24; h++) {
      // 0h is at top (12 o'clock), rotating clockwise
      final angle = (h * 15.0 - 90.0) * math.pi / 180.0;
      final outerP = Offset(center.dx + maxR * math.cos(angle), center.dy + maxR * math.sin(angle));
      final innerP = Offset(
        center.dx + (maxR - (h % 6 == 0 ? 10 : 5)) * math.cos(angle),
        center.dy + (maxR - (h % 6 == 0 ? 10 : 5)) * math.sin(angle),
      );
      canvas.drawLine(innerP, outerP, tickPaint);

      // Major labels (0h, 6h, 12h, 18h)
      if (h % 3 == 0) {
        final labelP = Offset(
          center.dx + (maxR - 22) * math.cos(angle),
          center.dy + (maxR - 22) * math.sin(angle),
        );
        tp.text = TextSpan(
          text: '${h}h',
          style: TextStyle(
            color: h == 0 ? AppColors.secondary : AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        );
        tp.layout();
        tp.paint(canvas, labelP - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Reticle Center Text: NCP or SCP
    tp.text = TextSpan(
      text: isNorthern ? 'NCP' : 'SCP',
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx + 6, center.dy + 6));

    if (isNorthern) {
      // NORTHERN HEMISPHERE: POLARIS
      // Polaris position on the circle:
      // Hour angle 0h is at top (theta = -90 deg)
      final polarisAngleRad = (hourAngleDeg - 90.0) * math.pi / 180.0;
      final starPos = Offset(
        center.dx + polarisRadius * math.cos(polarisAngleRad),
        center.dy + polarisRadius * math.sin(polarisAngleRad),
      );

      // Glow behind Polaris
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(starPos, 8, glowPaint);

      // Targeted alignment reticle ring for Polaris
      final targetCirclePaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(starPos, 7.5, targetCirclePaint);

      // Polaris star center point
      final starPaint = Paint()..color = Colors.white;
      canvas.drawCircle(starPos, 3.5, starPaint);

      // Polaris label
      tp.text = const TextSpan(
        text: 'POLARIS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          backgroundColor: Colors.black54,
        ),
      );
      tp.layout();
      final labelOffset = Offset(
        (starPos.dx - tp.width / 2).clamp(10.0, size.width - tp.width - 10.0),
        (starPos.dy > center.dy ? starPos.dy + 12 : starPos.dy - 22),
      );
      tp.paint(canvas, labelOffset);
    } else {
      // SOUTHERN HEMISPHERE: OCTANS TRAPEZOID
      // Sigma Octantis, Chi, Tau, Upsilon
      final baseRad = (hourAngleDeg - 90.0) * math.pi / 180.0;

      // 4 stars of Octans Trapezoid relative to SCP
      final sOct = Offset(
        center.dx + polarisRadius * math.cos(baseRad),
        center.dy + polarisRadius * math.sin(baseRad),
      );
      final chiOct = Offset(
        center.dx + (polarisRadius * 1.35) * math.cos(baseRad - 0.42),
        center.dy + (polarisRadius * 1.35) * math.sin(baseRad - 0.42),
      );
      final tauOct = Offset(
        center.dx + (polarisRadius * 1.6) * math.cos(baseRad + 0.12),
        center.dy + (polarisRadius * 1.6) * math.sin(baseRad + 0.12),
      );
      final upsOct = Offset(
        center.dx + (polarisRadius * 1.5) * math.cos(baseRad - 0.22),
        center.dy + (polarisRadius * 1.5) * math.sin(baseRad - 0.22),
      );

      // Trapezoid constellation lines
      final trapLine = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.6)
        ..strokeWidth = 1.2;
      canvas.drawLine(sOct, chiOct, trapLine);
      canvas.drawLine(chiOct, upsOct, trapLine);
      canvas.drawLine(upsOct, tauOct, trapLine);
      canvas.drawLine(tauOct, sOct, trapLine);

      // Draw stars
      final starWhite = Paint()..color = Colors.white;
      canvas.drawCircle(sOct, 3.5, starWhite);
      canvas.drawCircle(chiOct, 3.0, starWhite);
      canvas.drawCircle(tauOct, 2.5, starWhite);
      canvas.drawCircle(upsOct, 2.5, starWhite);

      // Target reticle on Sigma Octantis
      final targetCirclePaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(sOct, 7.5, targetCirclePaint);

      tp.text = const TextSpan(
        text: 'σ Octantis',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          backgroundColor: Colors.black54,
        ),
      );
      tp.layout();
      tp.paint(canvas, sOct + const Offset(9, -6));
    }
  }

  @override
  bool shouldRepaint(covariant _PolarReticlePainter old) {
    return old.isNorthern != isNorthern ||
        old.hourAngleDeg != hourAngleDeg ||
        old.invertedView != invertedView ||
        old.polarDistanceArcmin != polarDistanceArcmin;
  }
}
