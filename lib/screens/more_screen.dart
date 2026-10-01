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
          color: const Color(0xDD0B1224),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF233054),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
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
            child: Row(
              children: [
                const SizedBox(width: 14),
                // 1. Left circular icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCC181E40),
                    border: Border.all(
                      color: const Color(0xFF6356DA),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6356DA).withValues(alpha: 0.35),
                        blurRadius: 8,
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
                const SizedBox(width: 12),
                // 2. Title and Subtitle (flexibly expands)
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
                const SizedBox(width: 4),
                // 3. Right-side Dedicated Graphic Area (width: 96, height: 72)
                SizedBox(
                  width: 96,
                  height: 72,
                  child: item.graphic,
                ),
                // 4. Chevron right arrow with clean dedicated padding (no collisions!)
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7D8FA9),
                    size: 20,
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

/// 1. Framing Simulator: Sensor reticle box with corner brackets around galaxy
class _FramingSimGraphic extends StatelessWidget {
  const _FramingSimGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 84,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF070B18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF263258), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/telescope_galaxy_art.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/header_sky.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(
                painter: _SensorReticlePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorReticlePainter extends CustomPainter {
  const _SensorReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    const b = 4.0;
    const l = 7.0;

    // Top-left
    canvas.drawLine(const Offset(b, b), const Offset(b + l, b), paint);
    canvas.drawLine(const Offset(b, b), const Offset(b, b + l), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - b, b), Offset(size.width - b - l, b), paint);
    canvas.drawLine(
        Offset(size.width - b, b), Offset(size.width - b, b + l), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(b, size.height - b), Offset(b + l, size.height - b), paint);
    canvas.drawLine(
        Offset(b, size.height - b), Offset(b, size.height - b - l), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - b, size.height - b),
        Offset(size.width - b - l, size.height - b), paint);
    canvas.drawLine(Offset(size.width - b, size.height - b),
        Offset(size.width - b, size.height - b - l), paint);

    // Subtle center cross
    final cx = size.width / 2;
    final cy = size.height / 2;
    final centerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(cx - 3, cy), Offset(cx + 3, cy), centerPaint);
    canvas.drawLine(Offset(cx, cy - 3), Offset(cx, cy + 3), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Polar Alignment Clock: Concentric circles, radial lines, Polaris & mountain
class _PolarClockGraphic extends StatelessWidget {
  const _PolarClockGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _PolarClockPainter(),
    );
  }
}

class _PolarClockPainter extends CustomPainter {
  const _PolarClockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 28.0;

    // Outer grid rings
    final ringPaint = Paint()
      ..color = const Color(0xFF3862A8).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.35, ringPaint);

    // Radial hour angle lines
    final linePaint = Paint()
      ..color = const Color(0xFF3862A8).withValues(alpha: 0.35)
      ..strokeWidth = 0.9;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(center.dx + radius * 0.25 * math.cos(angle),
            center.dy + radius * 0.25 * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle)),
        linePaint,
      );
    }

    // Mountain silhouette at bottom
    final mountain = Path()
      ..moveTo(center.dx - radius, center.dy + radius)
      ..lineTo(center.dx - 12, center.dy + 8)
      ..lineTo(center.dx, center.dy + 14)
      ..lineTo(center.dx + 16, center.dy + 6)
      ..lineTo(center.dx + radius, center.dy + radius)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = const Color(0xFF091024),
    );

    // 'N' label at top
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - 3.5, center.dy - radius - 1));

    // Polaris star glowing at hour angle (10 o'clock)
    const starAngle = -math.pi * 0.65;
    final starCenter = Offset(
      center.dx + radius * 0.65 * math.cos(starAngle),
      center.dy + radius * 0.65 * math.sin(starAngle),
    );
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(starCenter, 3.5, glowPaint);
    canvas.drawCircle(
      starCenter,
      1.8,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Session Scheduler: Glass calendar with schedule dot grid
class _SessionSchedulerGraphic extends StatelessWidget {
  const _SessionSchedulerGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xEE141938),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF5E48C8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E48C8).withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            // Calendar top binder
            Container(
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF6C5CE7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (index) => Container(
                    width: 3.5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Schedule dot grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _dot(const Color(0xFF00E5FF)),
                        _dot(const Color(0xFFB388FF)),
                        _dot(Colors.white70),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _dot(Colors.white38),
                        _dot(const Color(0xFF00E5FF)),
                        _dot(const Color(0xFFB388FF)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 4. Point-to-Sky Compass: 3D compass rose, cardinal points, mountain ridge
class _CompassGraphic extends StatelessWidget {
  const _CompassGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _CompassPainter(),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 28.0;

    // Outer compass ring
    final ringPaint = Paint()
      ..color = const Color(0xFF324A75).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, ringPaint);

    // Cyan crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75)
      ..strokeWidth = 1.1;
    canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        crossPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius),
        crossPaint);

    // Mountain ridge along bottom
    final ridge = Path()
      ..moveTo(center.dx - radius, center.dy + radius)
      ..lineTo(center.dx - 10, center.dy + 12)
      ..lineTo(center.dx + 4, center.dy + 18)
      ..lineTo(center.dx + radius, center.dy + radius)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF0A1226));

    // Cardinal letters
    _drawChar(canvas, 'N', Offset(center.dx - 3.5, center.dy - radius - 1),
        const Color(0xFF00E5FF));
    _drawChar(canvas, 'S', Offset(center.dx - 3.5, center.dy + radius - 9),
        const Color(0xFF90A4AE));
    _drawChar(canvas, 'W', Offset(center.dx - radius + 2, center.dy - 5),
        const Color(0xFF90A4AE));
    _drawChar(canvas, 'E', Offset(center.dx + radius - 9, center.dy - 5),
        const Color(0xFF90A4AE));
  }

  void _drawChar(Canvas canvas, String char, Offset offset, Color color) {
    final p = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Night Mode & Red Light: Tactical flashlight casting wide crimson cone
class _RedLightGraphic extends StatelessWidget {
  const _RedLightGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _RedFlashlightPainter(),
    );
  }
}

class _RedFlashlightPainter extends CustomPainter {
  const _RedFlashlightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Flashlight sits at left-center, shining bright red cone to the right
    final emitter = Offset(28, size.height / 2 + 4);

    // Wide, vivid conical light beam
    final beam = Path()
      ..moveTo(emitter.dx, emitter.dy - 4)
      ..lineTo(size.width, emitter.dy - 24)
      ..lineTo(size.width, emitter.dy + 24)
      ..lineTo(emitter.dx, emitter.dy + 4)
      ..close();

    final beamPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerLeft,
        colors: [
          const Color(0xFFFF1744).withValues(alpha: 0.95),
          const Color(0xFFD50000).withValues(alpha: 0.55),
          const Color(0xFF8A0000).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(beam.getBounds());
    canvas.drawPath(beam, beamPaint);

    // Flashlight body (tactical black & dark gray)
    canvas.save();
    canvas.translate(emitter.dx, emitter.dy);
    canvas.rotate(0.08);

    // Grip handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -4, 18, 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1E2433),
    );

    // Beveled head
    final head = Path()
      ..moveTo(-2, -4)
      ..lineTo(4, -6)
      ..lineTo(4, 6)
      ..lineTo(-2, 4)
      ..close();
    canvas.drawPath(head, Paint()..color = const Color(0xFF2C354E));

    // Red lens bezel
    canvas.drawRect(
      const Rect.fromLTWH(4, -6, 2, 12),
      Paint()..color = const Color(0xFFFF5252),
    );

    // Emitter flare
    canvas.drawCircle(
      const Offset(6, 0),
      4.5,
      Paint()
        ..color = const Color(0xFFFF1744)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      const Offset(6, 0),
      2.0,
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Location & GPS: Dotted 3D cyber globe with radiant purple beacon pin
class _LocationGpsGraphic extends StatelessWidget {
  const _LocationGpsGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _LocationGpsPainter(),
    );
  }
}

class _LocationGpsPainter extends CustomPainter {
  const _LocationGpsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    const radius = 24.0;

    // Dotted globe sphere
    final dotPaint = Paint()..color = const Color(0xFF4A68B0).withValues(alpha: 0.6);
    for (int i = 0; i < 18; i++) {
      final a = i * math.pi / 9;
      final dx = center.dx + radius * math.cos(a);
      final dy = center.dy + radius * math.sin(a) * 0.75;
      canvas.drawCircle(Offset(dx, dy), 1.2, dotPaint);
    }
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final dx = center.dx + (radius - 8) * math.cos(a);
      final dy = center.dy + (radius - 8) * math.sin(a) * 0.8;
      canvas.drawCircle(Offset(dx, dy), 1.2, dotPaint);
    }

    // Glowing location pin at top of globe
    final pinCenter = Offset(center.dx, center.dy - radius - 2);

    // Pulse wave rings
    canvas.drawCircle(
      pinCenter,
      8,
      Paint()
        ..color = const Color(0xFF8E72FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final pinIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_pin.codePoint),
        style: TextStyle(
          fontFamily: Icons.location_pin.fontFamily,
          package: Icons.location_pin.fontPackage,
          fontSize: 20,
          color: const Color(0xFFB388FF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pinIcon.paint(canvas, Offset(pinCenter.dx - 10, pinCenter.dy - 11));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. Weather: Night sky with moonlit silver-rimmed volumetric clouds
class _WeatherGraphic extends StatelessWidget {
  const _WeatherGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _CloudPainter(),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Starry sparkles
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width * 0.25, 14), 1.0, starPaint);
    canvas.drawCircle(Offset(size.width * 0.75, 12), 1.2, starPaint);
    canvas.drawCircle(Offset(size.width * 0.85, 26), 0.9, starPaint);

    // Moonlit halo behind cloud
    final moonHalo = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF90CAF9).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(size.width * 0.65, 24), radius: 22),
      );
    canvas.drawCircle(Offset(size.width * 0.65, 24), 22, moonHalo);

    // Crescent moon peeking
    final moonPaint = Paint()..color = const Color(0xFFE3F2FD);
    canvas.drawCircle(Offset(size.width * 0.65, 22), 7, moonPaint);
    canvas.drawCircle(
      Offset(size.width * 0.68, 20),
      6,
      Paint()..color = const Color(0xFF0B1224),
    );

    // Layered cloud body
    final cloudPaint = Paint()
      ..color = const Color(0xD0243457);
    final rimPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cloudPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(size.width * 0.38, 44), radius: 14))
      ..addOval(Rect.fromCircle(center: Offset(size.width * 0.56, 38), radius: 17))
      ..addOval(Rect.fromCircle(center: Offset(size.width * 0.72, 45), radius: 13));

    canvas.drawPath(cloudPath, cloudPaint);
    canvas.drawPath(cloudPath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 8. Moon: High-res 3D moon with cosmic halo and night clouds
class _MoonGraphic extends StatelessWidget {
  const _MoonGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8D6F2).withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/moon_3d.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.nightlight_round,
              size: 40,
              color: Color(0xFFC5CAE9),
            ),
          ),
        ),
      ),
    );
  }
}

/// 9. Sun & Twilight: Sunset gradient, horizontal horizon line, setting sun
class _SunTwilightGraphic extends StatelessWidget {
  const _SunTwilightGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _SunTwilightPainter(),
    );
  }
}

class _SunTwilightPainter extends CustomPainter {
  const _SunTwilightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);

    // Radiant sunset glow aura
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9800).withValues(alpha: 0.65),
          const Color(0xFFE91E63).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 28));
    canvas.drawCircle(center, 28, glow);

    // Glowing sun disc (half submerged)
    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFFFB74D));

    // Clean horizontal horizon line
    final horizonLine = Paint()
      ..color = const Color(0xFF6C7FB6)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(8, center.dy + 3),
      Offset(size.width - 8, center.dy + 3),
      horizonLine,
    );

    // Night shadow below horizon
    canvas.drawRect(
      Rect.fromLTWH(8, center.dy + 3.5, size.width - 16, 16),
      Paint()..color = const Color(0xCC070B18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10. Equipment: Professional camera/telescope optical lens with iris blades
class _EquipmentGraphic extends StatelessWidget {
  const _EquipmentGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _EquipmentPainter(),
    );
  }
}

class _EquipmentPainter extends CustomPainter {
  const _EquipmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Metallic barrel ring
    final ringPaint = Paint()
      ..color = const Color(0xFF384A78).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 24, ringPaint);

    // Multi-coated glass reflection
    final lensPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawCircle(center, 20, lensPaint);

    // 6 aperture iris diaphragm blades
    final bladePaint = Paint()
      ..color = const Color(0xFF141A34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        Offset(center.dx + 6 * math.cos(a), center.dy + 6 * math.sin(a)),
        Offset(center.dx + 18 * math.cos(a + 0.6),
            center.dy + 18 * math.sin(a + 0.6)),
        bladePaint,
      );
    }

    // Lens flare glint
    canvas.drawCircle(
      Offset(center.dx - 5, center.dy - 5),
      2.0,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 11. Offline Trip Pack: Cyber offline storage module with cyan capacity blocks
class _TripPackGraphic extends StatelessWidget {
  const _TripPackGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _TripPackPainter(),
    );
  }
}

class _TripPackPainter extends CustomPainter {
  const _TripPackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cartridge background
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 38);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));

    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF0F172E),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Download arrow icon / shape at top
    final arrowPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Arrow shaft and head
    canvas.drawLine(Offset(cx - 10, cy - 6), Offset(cx - 10, cy + 2), arrowPaint);
    canvas.drawLine(Offset(cx - 13, cy - 1), Offset(cx - 10, cy + 2), arrowPaint);
    canvas.drawLine(Offset(cx - 7, cy - 1), Offset(cx - 10, cy + 2), arrowPaint);

    // Status LED dot (glowing cyan)
    canvas.drawCircle(
      Offset(cx + 12, cy - 5),
      2.5,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(Offset(cx + 12, cy - 5), 1.5, Paint()..color = Colors.white);

    // 4 Storage capacity segments at bottom
    final barY = cy + 8;
    for (int i = 0; i < 4; i++) {
      final bx = cx - 18 + i * 9.5;
      final bRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, barY, 7.5, 4),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        bRect,
        Paint()
          ..color = i < 3
              ? const Color(0xFF00E5FF)
              : const Color(0xFF263258),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 12. Sync Center: Orbital satellite telemetry rings with radio waves
class _SyncCenterGraphic extends StatelessWidget {
  const _SyncCenterGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _SyncTelemetryPainter(),
    );
  }
}

class _SyncTelemetryPainter extends CustomPainter {
  const _SyncTelemetryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Dual inclined orbital rings
    final orbitPaint = Paint()
      ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 48, height: 22),
      orbitPaint,
    );
    canvas.rotate(0.8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 48, height: 22),
      orbitPaint,
    );

    // Orbiting satellite dot
    canvas.drawCircle(
      const Offset(22, 0),
      3.0,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      const Offset(22, 0),
      1.5,
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // Center telemetry node
    canvas.drawCircle(
      center,
      3.5,
      Paint()..color = const Color(0xFFB388FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 13. Settings: Precision calibration instrument with notched dial
class _SettingsGraphic extends StatelessWidget {
  const _SettingsGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _CalibrationDialPainter(),
    );
  }
}

class _CalibrationDialPainter extends CustomPainter {
  const _CalibrationDialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 22.0;

    // Outer notched calibration ring
    final dialPaint = Paint()
      ..color = const Color(0xFF5C6BC0).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(center, radius, dialPaint);

    // Precision calibration tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF9FA8DA).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final inner = radius - (i % 3 == 0 ? 5 : 3);
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(a), center.dy + inner * math.sin(a)),
        Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a)),
        tickPaint,
      );
    }

    // Inner indicator gear
    canvas.drawCircle(
      center,
      9.0,
      Paint()..color = const Color(0xFF1E284E),
    );
    canvas.drawCircle(
      center,
      3.0,
      Paint()..color = const Color(0xFF7C4DFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 14. About & Data: Astrophysics constellation network with connected star nodes
class _AboutGraphic extends StatelessWidget {
  const _AboutGraphic();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(96, 72),
      painter: _ConstellationNetworkPainter(),
    );
  }
}

class _ConstellationNetworkPainter extends CustomPainter {
  const _ConstellationNetworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final p1 = Offset(cx - 20, cy - 10);
    final p2 = Offset(cx - 4, cy - 16);
    final p3 = Offset(cx + 18, cy - 8);
    final p4 = Offset(cx + 8, cy + 14);
    final p5 = Offset(cx - 14, cy + 12);

    // Constellation lines
    final linePaint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(p1, p2, linePaint);
    canvas.drawLine(p2, p3, linePaint);
    canvas.drawLine(p3, p4, linePaint);
    canvas.drawLine(p4, p5, linePaint);
    canvas.drawLine(p5, p1, linePaint);
    canvas.drawLine(p2, p4, linePaint);

    // Star nodes
    final starPaint = Paint()..color = const Color(0xFF90CAF9);
    for (final p in [p1, p2, p4, p5]) {
      canvas.drawCircle(p, 2.2, starPaint);
    }

    // Main glowing alpha star at p3
    final alphaGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(p3, 4.0, alphaGlow);
    canvas.drawCircle(p3, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
