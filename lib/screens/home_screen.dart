import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../models/astro_target.dart';
import '../theme/app_theme.dart';
import '../widgets/target_tile.dart';

/// Clean 4-pointed sparkle star icon matching the AstroField logo in the mockup.
class AstroStarIcon extends StatelessWidget {
  const AstroStarIcon({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AstroStarPainter(),
    );
  }
}

class _AstroStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, 0);
    path.quadraticBezierTo(w * 0.5, h * 0.5, w, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, h);
    path.quadraticBezierTo(w * 0.5, h * 0.5, 0, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, 0);
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9E86FF), Color(0xFF7A55F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final glowPaint = Paint()
      ..color = const Color(0xFF7A55F7).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clean telescope on tripod vector icon matching the mockup.
class TelescopeIcon extends StatelessWidget {
  const TelescopeIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TelescopePainter(color: color),
    );
  }
}

class _TelescopePainter extends CustomPainter {
  _TelescopePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeW = size.width * 0.085;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Telescope barrel angled at ~35 deg from bottom-left to top-right
    canvas.drawLine(
      Offset(0.26 * w, 0.64 * h),
      Offset(0.82 * w, 0.22 * h),
      linePaint..strokeWidth = strokeW * 1.5,
    );

    // Front lens hood
    canvas.drawLine(
      Offset(0.77 * w, 0.16 * h),
      Offset(0.88 * w, 0.28 * h),
      linePaint..strokeWidth = strokeW * 1.3,
    );

    // Eyepiece at back
    canvas.drawLine(
      Offset(0.20 * w, 0.69 * h),
      Offset(0.26 * w, 0.64 * h),
      linePaint..strokeWidth = strokeW * 0.9,
    );

    // Mount joint
    canvas.drawCircle(Offset(0.48 * w, 0.48 * h), strokeW * 1.1, fillPaint);

    // Tripod center leg
    canvas.drawLine(
      Offset(0.48 * w, 0.48 * h),
      Offset(0.48 * w, 0.88 * h),
      linePaint..strokeWidth = strokeW * 0.9,
    );
    // Left leg
    canvas.drawLine(
      Offset(0.48 * w, 0.48 * h),
      Offset(0.18 * w, 0.88 * h),
      linePaint..strokeWidth = strokeW * 0.9,
    );
    // Right leg
    canvas.drawLine(
      Offset(0.48 * w, 0.48 * h),
      Offset(0.78 * w, 0.88 * h),
      linePaint..strokeWidth = strokeW * 0.9,
    );
  }

  @override
  bool shouldRepaint(covariant _TelescopePainter oldDelegate) =>
      oldDelegate.color != color;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _formatDateTime(DateTime dt) {
    final m = dt.month;
    final d = dt.day;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m/$d $h:$min $ampm';
  }

  Future<void> _chooseTime(BuildContext context, FieldController c) async {
    final current = c.time.value.toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    c.live.value = false;
    c.time.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toUtc();
    await c.refresh();
  }

  String _darknessState(double sunAltitude) {
    if (sunAltitude > 0) return 'Daylight';
    if (sunAltitude > -6) return 'Civil twilight';
    if (sunAltitude > -12) return 'Nautical twilight';
    if (sunAltitude > -18) return 'Astronomical twilight';
    return 'Astronomical darkness';
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final r = c.report.value;
        final site = c.site.value;
        final topTargets = c.targets().where((t) => t.score > 0).take(4).toList();
        final sunAlt = r?.sun.altitude ?? 15.0;
        final darkness = _darknessState(sunAlt);
        final moonIllum = r != null ? (r.moonIllumination * 100).round() : 91;

        return Stack(
          children: [
            // Top Starry Night Atmosphere Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 400,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/header_sky.png',
                    width: double.infinity,
                    height: 400,
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
                          AppColors.background.withValues(alpha: 0.35),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Foreground Scrollable Content
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  // --- 1. Top Header Row ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // 4-point glowing star logo icon
                          const AstroStarIcon(size: 26),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AstroField',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              Text(
                                '${site?.name ?? "GPS site"} (accuracy 100 m).',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Location & Menu Action Icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Location Icon Button (Circle)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Get.toNamed(AppRoutes.location),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface2.withValues(alpha: 0.8),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.secondary,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hamburger Menu Button (opens AstroDrawer)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface2.withValues(alpha: 0.8),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.menu_rounded,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --- 2. Date & Time Pill Button ---
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _chooseTime(context, c),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(c.time.value.toLocal()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.live.value ? 'device time' : 'simulated time',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- 3. Card 1: "Current sky" with 3D Glowing Moon ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF081125).withValues(alpha: 0.6),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left Crescent Moon Icon Container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0E1830),
                            border: Border.all(
                              color: AppColors.electricBlue.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricBlue.withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.dark_mode_outlined,
                              color: AppColors.secondary,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Text Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current sky',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: darkness,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' • ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Moon $moonIllum% illuminated',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_formatDateTime(c.time.value.toLocal())} • device timezone',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Realistic 3D Glowing Moon
                        Container(
                          width: 82,
                          height: 82,
                          margin: const EdgeInsets.only(left: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/moon_3d.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE0E5F5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- 4. Three Action Buttons: [Catalog] [Weather] [Equipment] ---
                  Row(
                    children: [
                      // 1. Catalog Button (Gradient Glow Pill)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.toNamed(AppRoutes.search),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5A58D7),
                                  Color(0xFF7A55F7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(23),
                              border: Border.all(
                                color: const Color(0xFF7A55F7),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7A55F7).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Catalog',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 2. Weather Button
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.toNamed(AppRoutes.weather),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(23),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_outlined,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Weather',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 3. Equipment Button
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.toNamed(AppRoutes.equipment),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(23),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TelescopeIcon(
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Equipment',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --- 5. Card 2: "Best targets now" with Shooting Star Mountains ---
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Get.toNamed(AppRoutes.search),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF081125).withValues(alpha: 0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Purple glowing target badge
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF172342),
                                          border: Border.all(
                                            color: AppColors.violet.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.violet.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.track_changes_rounded,
                                            color: AppColors.violet,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Best targets now',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ranked by altitude, darkness and Moon interference. Minimum altitude ${c.minimumAltitude.value.round()}°.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Shooting star mountains artwork
                            Image.asset(
                              'assets/images/best_targets_art.png',
                              width: double.infinity,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(height: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- 6. Card 3: "No matching targets" (or Best Targets List) ---
                  if (topTargets.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF081125).withValues(alpha: 0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Blue glowing telescope badge
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF172342),
                                          border: Border.all(
                                            color: AppColors.secondary.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.secondary.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: TelescopeIcon(
                                            size: 18,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'No matching targets',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Try the catalog, another time, or a different altitude threshold.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Telescope and Spiral Galaxy artwork
                            Image.asset(
                              'assets/images/telescope_galaxy_art.png',
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(height: 20),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // When targets are visible, display them with sleek tiles
                    ...topTargets.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TargetTile(target: AstroTarget.fromTargetPlan(t)),
                        )),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
