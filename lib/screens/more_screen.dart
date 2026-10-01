import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _MoreItem(
        icon: Icons.track_changes_rounded,
        title: 'Framing Simulator',
        subtitle: 'Visualize FOV, rotation & target size',
        route: AppRoutes.framingSimulator,
        graphic: _FramingSimGraphic(),
      ),
      const _MoreItem(
        icon: Icons.explore_rounded,
        title: 'Polar Alignment Clock',
        subtitle: 'Find RA & Octans hour angle',
        route: AppRoutes.polarAlignment,
        graphic: _PolarClockGraphic(),
      ),
      const _MoreItem(
        icon: Icons.show_chart_rounded,
        title: 'Session Scheduler',
        subtitle: 'Plan targets, sequences & observing windows',
        route: AppRoutes.sessionScheduler,
        graphic: _SessionSchedulerGraphic(),
      ),
      const _MoreItem(
        icon: Icons.navigation_rounded,
        title: 'Point-to-Sky Compass',
        subtitle: 'Live compass & horizon mask',
        route: AppRoutes.pointToSky,
        graphic: _CompassGraphic(),
      ),
      const _MoreItem(
        icon: Icons.flashlight_on_rounded,
        title: 'Night Mode & Red Light',
        subtitle: 'Dark adaptation, red screen & light tools',
        route: AppRoutes.redLightTools,
        graphic: _RedLightGraphic(),
      ),
      const _MoreItem(
        icon: Icons.location_on_rounded,
        title: 'Location & GPS',
        subtitle: 'Current coordinates and observing site',
        route: AppRoutes.location,
        graphic: _LocationGpsGraphic(),
      ),
      const _MoreItem(
        icon: Icons.cloud_outlined,
        title: 'Weather',
        subtitle: 'Astronomy conditions and forecast',
        route: AppRoutes.weather,
        graphic: _WeatherGraphic(),
      ),
      const _MoreItem(
        icon: Icons.nightlight_round,
        title: 'Moon',
        subtitle: 'Phase, illumination and moon times',
        route: AppRoutes.moon,
        graphic: _MoonGraphic(),
      ),
      const _MoreItem(
        icon: Icons.wb_twilight_rounded,
        title: 'Sun & twilight',
        subtitle: 'Sunset and astronomical darkness',
        route: AppRoutes.sunTwilight,
        graphic: _SunTwilightGraphic(),
      ),
      const _MoreItem(
        icon: Icons.camera_outlined,
        title: 'Equipment',
        subtitle: 'Camera, telescope and field of view',
        route: AppRoutes.equipment,
        graphic: _EquipmentGraphic(),
      ),
      const _MoreItem(
        icon: Icons.download_for_offline_rounded,
        title: 'Offline trip pack',
        subtitle: 'Prepare everything before travel',
        route: AppRoutes.tripPack,
        graphic: _TripPackGraphic(),
      ),
      const _MoreItem(
        icon: Icons.sync_rounded,
        title: 'Sync center',
        subtitle: 'Fresh data and local cache status',
        route: AppRoutes.sync,
        graphic: _SyncCenterGraphic(),
      ),
      const _MoreItem(
        icon: Icons.settings_suggest_rounded,
        title: 'Settings',
        subtitle: 'Units, thresholds and app preferences',
        route: AppRoutes.settings,
        graphic: _SettingsGraphic(),
      ),
      const _MoreItem(
        icon: Icons.info_outline_rounded,
        title: 'About & data',
        subtitle: 'Offline engine and source notes',
        route: AppRoutes.about,
        graphic: _AboutGraphic(),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Cosmic starry nebula & mountain silhouette backdrop
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 420,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/header_sky.png',
                  width: double.infinity,
                  height: 420,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.25),
                        AppColors.background.withValues(alpha: 0.85),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.45, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2. Main content list
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                const SizedBox(height: 6),
                const Text(
                  'More',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Field tools and offline controls',
                  style: TextStyle(
                    color: Color(0xFF8A9BB8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                ...items.map((item) => _buildCard(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_MoreItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xCC0D1427),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF263258),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Get.toNamed(item.route),
            child: Stack(
              children: [
                // Right-side illustrated artwork
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 145,
                  child: item.graphic,
                ),
                // Left content: Badge, Title, Subtitle, and Chevron
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xCC1A1F44),
                          border: Border.all(
                            color: const Color(0xFF6B5BE2),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B5BE2)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            color: const Color(0xFF9AA8FF),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8A9BB8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFB0BEC5),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.graphic,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Widget graphic;
}

// ---------------------------------------------------------------------------
// Custom Illustrated Artworks for Right Side of Cards
// ---------------------------------------------------------------------------

class _FramingSimGraphic extends StatelessWidget {
  const _FramingSimGraphic();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/telescope_galaxy_art.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/header_sky.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF0D1427),
                  Color(0xCC0D1427),
                  Colors.transparent,
                ],
                stops: [0.0, 0.35, 0.75],
              ),
            ),
          ),
        ),
        const Positioned(
          right: 22,
          top: 14,
          bottom: 14,
          width: 80,
          child: CustomPaint(
            painter: _SensorReticlePainter(),
          ),
        ),
      ],
    );
  }
}

class _SensorReticlePainter extends CustomPainter {
  const _SensorReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x99A0B8FF)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    const arm = 9.0;
    canvas.drawLine(const Offset(0, 0), const Offset(arm, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(0, arm), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - arm, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), p);
    canvas.drawLine(Offset(0, size.height), Offset(arm, size.height), p);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - arm), p);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - arm, size.height), p);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - arm), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PolarClockGraphic extends StatelessWidget {
  const _PolarClockGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(145, 80),
      painter: const _PolarClockPainter(),
    );
  }
}

class _PolarClockPainter extends CustomPainter {
  const _PolarClockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0D1427), Color(0x440D1427), Colors.transparent],
        stops: [0.0, 0.4, 0.8],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final center = Offset(size.width - 40, size.height / 2);
    final ringPaint = Paint()
      ..color = const Color(0x444D8BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final r in [18.0, 36.0, 54.0]) {
      canvas.drawCircle(center, r, ringPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0x334D8BFF)
      ..strokeWidth = 0.9;

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(center.dx + 12 * math.cos(angle),
            center.dy + 12 * math.sin(angle)),
        Offset(center.dx + 54 * math.cos(angle),
            center.dy + 54 * math.sin(angle)),
        linePaint,
      );
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFF00E5FF),
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - 4, center.dy - 52));

    final starCenter = Offset(center.dx - 10, center.dy - 12);
    final glowPaint = Paint()
      ..color = const Color(0xFF82B1FF).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(starCenter, 4, glowPaint);

    final starCore = Paint()..color = Colors.white;
    canvas.drawCircle(starCenter, 2, starCore);

    final mtnPath = Path();
    mtnPath.moveTo(size.width - 90, size.height);
    mtnPath.lineTo(size.width - 65, size.height - 18);
    mtnPath.lineTo(size.width - 45, size.height - 8);
    mtnPath.lineTo(size.width - 20, size.height - 24);
    mtnPath.lineTo(size.width, size.height - 6);
    mtnPath.lineTo(size.width, size.height);
    mtnPath.close();

    final mtnPaint = Paint()..color = const Color(0xFF060B18);
    canvas.drawPath(mtnPath, mtnPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SessionSchedulerGraphic extends StatelessWidget {
  const _SessionSchedulerGraphic();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/header_sky.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF0D1427), Colors.transparent],
                stops: [0.0, 0.45],
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xCC1A1F48),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF7A64E0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7A64E0).withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFC5CAE9),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompassGraphic extends StatelessWidget {
  const _CompassGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(145, 80),
      painter: const _CompassPainter(),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 38, size.height / 2);
    const radius = 32.0;

    final glowPaint = Paint()
      ..color = const Color(0xFF3865D8).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius, glowPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF4C75E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, ringPaint);

    final tickPaint = Paint()
      ..color = const Color(0xFF82B1FF)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final inner = radius - (i % 3 == 0 ? 5 : 3);
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(a),
            center.dy + inner * math.sin(a)),
        Offset(center.dx + radius * math.cos(a),
            center.dy + radius * math.sin(a)),
        tickPaint,
      );
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final entry in {
      'N': Offset(center.dx - 3, center.dy - radius + 3),
      'S': Offset(center.dx - 3, center.dy + radius - 11),
      'E': Offset(center.dx + radius - 11, center.dy - 4),
      'W': Offset(center.dx - radius + 3, center.dy - 4),
    }.entries) {
      tp.text = TextSpan(
        text: entry.key,
        style: const TextStyle(
          color: Color(0xFF82B1FF),
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      );
      tp.layout();
      tp.paint(canvas, entry.value);
    }

    final needlePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx, center.dy - 14),
      Offset(center.dx, center.dy + 14),
      needlePaint,
    );
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      needlePaint,
    );

    final mtnPath = Path();
    mtnPath.moveTo(size.width - 85, size.height);
    mtnPath.lineTo(size.width - 60, size.height - 15);
    mtnPath.lineTo(size.width - 35, size.height - 24);
    mtnPath.lineTo(size.width - 15, size.height - 12);
    mtnPath.lineTo(size.width, size.height - 18);
    mtnPath.lineTo(size.width, size.height);
    mtnPath.close();

    final mtnPaint = Paint()..color = const Color(0xFF050A16);
    canvas.drawPath(mtnPath, mtnPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RedLightGraphic extends StatelessWidget {
  const _RedLightGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(145, 80),
      painter: const _RedFlashlightPainter(),
    );
  }
}

class _RedFlashlightPainter extends CustomPainter {
  const _RedFlashlightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final beamPath = Path();
    final origin = Offset(size.width - 70, size.height / 2 + 8);
    beamPath.moveTo(origin.dx, origin.dy - 6);
    beamPath.lineTo(size.width + 10, size.height / 2 - 32);
    beamPath.lineTo(size.width + 10, size.height / 2 + 42);
    beamPath.lineTo(origin.dx, origin.dy + 6);
    beamPath.close();

    final beamPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerLeft,
        colors: [
          const Color(0xFFFF1744).withValues(alpha: 0.8),
          const Color(0xFFD50000).withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(beamPath.getBounds());
    canvas.drawPath(beamPath, beamPaint);

    canvas.save();
    canvas.translate(origin.dx - 12, origin.dy);
    canvas.rotate(0.35);

    final bodyPaint = Paint()..color = const Color(0xFF1E2435);
    final rimPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-28, -5, 34, 10),
        const Radius.circular(3),
      ),
      bodyPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, -8, 12, 16),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2C354E),
    );
    canvas.drawRect(const Rect.fromLTWH(16, -7, 3, 14), rimPaint);

    canvas.drawCircle(
      const Offset(18, 0),
      6,
      Paint()
        ..color = const Color(0xFFFF1744)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocationGpsGraphic extends StatelessWidget {
  const _LocationGpsGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(145, 80),
      painter: const _LocationGpsPainter(),
    );
  }
}

class _LocationGpsPainter extends CustomPainter {
  const _LocationGpsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 34, size.height / 2 + 10);
    const radius = 38.0;

    final globePaint = Paint()
      ..color = const Color(0x444D8BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, globePaint);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 1.4, height: radius * 2),
      globePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.9),
      globePaint,
    );

    final dotPaint = Paint()..color = const Color(0x6682B1FF);
    for (int i = 0; i < 20; i++) {
      final a = i * 0.38;
      final dx = center.dx + (radius - 6) * math.cos(a) * 0.8;
      final dy = center.dy + (radius - 6) * math.sin(a) * 0.8;
      canvas.drawCircle(Offset(dx, dy), 1.2, dotPaint);
    }

    final pinCenter = Offset(center.dx - 6, center.dy - radius - 2);
    final pulsePaint = Paint()
      ..color = const Color(0xFF6B5BE2).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(pinCenter, 10, pulsePaint);

    final pinIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_pin.codePoint),
        style: TextStyle(
          fontFamily: Icons.location_pin.fontFamily,
          package: Icons.location_pin.fontPackage,
          fontSize: 22,
          color: const Color(0xFF8E72FF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pinIcon.paint(canvas, Offset(pinCenter.dx - 11, pinCenter.dy - 11));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeatherGraphic extends StatelessWidget {
  const _WeatherGraphic();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/header_sky.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF0D1427), Colors.transparent],
                stops: [0.0, 0.45],
              ),
            ),
          ),
        ),
        const Positioned(
          right: 18,
          top: 14,
          bottom: 12,
          width: 80,
          child: CustomPaint(
            painter: _CloudPainter(),
          ),
        ),
      ],
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = const Color(0xCC7A8BA8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final highlightPaint = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    path.addOval(
        Rect.fromCircle(center: Offset(size.width - 24, 26), radius: 14));
    path.addOval(
        Rect.fromCircle(center: Offset(size.width - 40, 30), radius: 16));
    path.addOval(
        Rect.fromCircle(center: Offset(size.width - 15, 34), radius: 12));
    path.addOval(
        Rect.fromCircle(center: Offset(size.width - 32, 40), radius: 15));

    canvas.drawPath(path, cloudPaint);
    canvas.drawCircle(Offset(size.width - 24, 20), 8, highlightPaint);
    canvas.drawCircle(Offset(size.width - 40, 24), 9, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MoonGraphic extends StatelessWidget {
  const _MoonGraphic();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/header_sky.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF0D1427), Colors.transparent],
                stops: [0.0, 0.45],
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 10,
          bottom: 10,
          child: Image.asset(
            'assets/images/moon_3d.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.nightlight_round,
              size: 42,
              color: Color(0xFFC5CAE9),
            ),
          ),
        ),
      ],
    );
  }
}

class _SunTwilightGraphic extends StatelessWidget {
  const _SunTwilightGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(145, 80),
      painter: const _SunTwilightPainter(),
    );
  }
}

class _SunTwilightPainter extends CustomPainter {
  const _SunTwilightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 40, size.height / 2 + 10);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9800).withValues(alpha: 0.6),
          const Color(0xFFE91E63).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 36));
    canvas.drawCircle(center, 36, glow);

    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFFFFCC80));

    final horizonLine = Paint()
      ..color = const Color(0xFF5C6BC0)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width - 85, center.dy + 4),
        Offset(size.width, center.dy + 4), horizonLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EquipmentGraphic extends StatelessWidget {
  const _EquipmentGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(145, 80),
      painter: const _EquipmentPainter(),
    );
  }
}

class _EquipmentPainter extends CustomPainter {
  const _EquipmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 38, size.height / 2);
    final ringPaint = Paint()
      ..color = const Color(0xFF3F51B5).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 28, ringPaint);

    final lensPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 24));
    canvas.drawCircle(center, 24, lensPaint);

    final aperturePaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        Offset(center.dx + 8 * math.cos(a), center.dy + 8 * math.sin(a)),
        Offset(center.dx + 22 * math.cos(a + 0.6),
            center.dy + 22 * math.sin(a + 0.6)),
        aperturePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TripPackGraphic extends StatelessWidget {
  const _TripPackGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC1A1F44),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.cloud_download_rounded,
            color: Color(0xFF80DEEA),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SyncCenterGraphic extends StatelessWidget {
  const _SyncCenterGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC1A1F44),
          border: Border.all(color: const Color(0xFF7C4DFF), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.sync_rounded,
            color: Color(0xFFB388FF),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SettingsGraphic extends StatelessWidget {
  const _SettingsGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC1A1F44),
          border: Border.all(color: const Color(0xFF5C6BC0), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C6BC0).withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.settings_suggest_rounded,
            color: Color(0xFF9FA8DA),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _AboutGraphic extends StatelessWidget {
  const _AboutGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC1A1F44),
          border: Border.all(color: const Color(0xFF42A5F5), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42A5F5).withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF90CAF9),
            size: 22,
          ),
        ),
      ),
    );
  }
}
