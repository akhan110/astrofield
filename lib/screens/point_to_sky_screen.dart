import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/field_controller.dart';
import '../domain/field_models.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class PointToSkyScreen extends StatefulWidget {
  const PointToSkyScreen({super.key});

  @override
  State<PointToSkyScreen> createState() => _PointToSkyScreenState();
}

class _PointToSkyScreenState extends State<PointToSkyScreen> {
  // Center of view in sky coordinates
  double _azimuth = 180.0; // 0° - 360° (start facing South)
  double _altitude = 45.0; // -10° to 90°

  // Selected locked target for radar guidance
  String? _lockedTargetId;

  // View settings
  bool _showLabels = true;
  bool _showGrid = true;
  bool _showFov = true;
  bool _redMode = false;

  // Equipment FOV preset in degrees (horizontal x vertical)
  double _fovH = 15.0; // Default ~135mm lens on Full Frame
  double _fovV = 10.0;
  String _fovPresetName = '135mm (FF)';

  final Map<String, (double, double, String)> _fovPresets = {
    '14mm Ultrawide': (104.0, 81.0, '14mm (FF)'),
    '24mm Wide': (73.7, 53.1, '24mm (FF)'),
    '50mm Normal': (39.6, 27.0, '50mm (FF)'),
    '135mm Medium Tele': (15.2, 10.2, '135mm (FF)'),
    '250mm RedCat': (8.2, 5.5, '250mm (APS-C)'),
    '400mm Telephoto': (5.1, 3.4, '400mm (FF)'),
    '800mm Telescope': (1.6, 1.1, '800mm (APS-C)'),
  };

  @override
  void initState() {
    super.initState();
    final c = Get.find<FieldController>();
    // Pre-lock best target tonight if available
    final targets = c.targets(tonight: true);
    if (targets.isNotEmpty) {
      _lockedTargetId = targets.first.object.id;
      // Center view on this target initially
      _azimuth = targets.first.now.azimuth;
      _altitude = targets.first.now.altitude.clamp(5.0, 85.0);
    }
  }

  void _centerOnTarget(TargetPlan plan) {
    setState(() {
      _lockedTargetId = plan.object.id;
      _azimuth = (plan.now.azimuth) % 360.0;
      _altitude = plan.now.altitude.clamp(-10.0, 90.0);
    });
  }

  void _showTargetPicker(BuildContext context, FieldController controller) {
    final searchCtrl = TextEditingController();
    var filter = 'All';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allTargets = controller.report.value?.targets ?? <TargetPlan>[];
            final query = searchCtrl.text.trim().toLowerCase();

            final filtered = allTargets.where((t) {
              if (query.isNotEmpty) {
                final match = '${t.object.id} ${t.object.name} ${t.object.type}'
                    .toLowerCase()
                    .contains(query);
                if (!match) return false;
              }
              if (filter == 'Messier') return RegExp(r'^M\d+$').hasMatch(t.object.id);
              if (filter == 'Nebulae') return t.object.type.toLowerCase().contains('nebula');
              if (filter == 'Galaxies') return t.object.type.toLowerCase().contains('galaxy');
              if (filter == 'Clusters') return t.object.type.toLowerCase().contains('cluster');
              if (filter == 'Planets') return t.object.type == 'Planet';
              return true;
            }).toList();

            filtered.sort((a, b) => b.now.altitude.compareTo(a.now.altitude));

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lock Guiding Target',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search object (e.g. M42, Andromeda)...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: AppColors.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Messier', 'Nebulae', 'Galaxies', 'Clusters', 'Planets']
                              .map((f) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(f, style: const TextStyle(fontSize: 11)),
                                      selected: filter == f,
                                      onSelected: (val) {
                                        if (val) setSheetState(() => filter = f);
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final p = filtered[idx];
                            final isVisible = p.now.altitude > 0;
                            final isSelected = _lockedTargetId == p.object.id;

                            return Card(
                              color: isSelected
                                  ? AppColors.secondary.withValues(alpha: 0.15)
                                  : AppColors.surface2,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.border,
                                ),
                              ),
                              child: ListTile(
                                onTap: () {
                                  _centerOnTarget(p);
                                  Navigator.of(context).pop();
                                },
                                title: Text(
                                  '${p.object.id} · ${p.object.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  'Alt: ${p.now.altitude.toStringAsFixed(1)}° (${p.now.direction}) · Az: ${p.now.azimuth.toStringAsFixed(0)}°',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isVisible
                                            ? AppColors.primary
                                            : AppColors.border)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isVisible ? 'Above Horizon' : 'Below Horizon',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isVisible
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showFovPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Camera Sensor FOV Overlay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Displays the framing rectangle your optics will capture.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Enable FOV Overlay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                value: _showFov,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) {
                  setState(() => _showFov = v);
                  Navigator.of(context).pop();
                },
              ),
              const Divider(height: 14, color: AppColors.border),
              ..._fovPresets.entries.map((e) {
                final isSel = _fovPresetName == e.value.$3;
                return ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: isSel
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  title: Text(
                    e.key,
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.secondary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${e.value.$1}° × ${e.value.$2}° FOV',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: isSel
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.secondary, size: 20)
                      : null,
                  onTap: () {
                    setState(() {
                      _fovH = e.value.$1;
                      _fovV = e.value.$2;
                      _fovPresetName = e.value.$3;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FieldController>();

    return Obx(() {
      final rep = controller.report.value;
      final targets = rep?.targets ?? <TargetPlan>[];

      TargetPlan? lockedTarget;
      if (_lockedTargetId != null) {
        lockedTarget = targets
            .where((t) => t.object.id == _lockedTargetId)
            .firstOrNull;
      }

      // Guidance Delta Calculations
      double deltaAz = 0;
      double deltaAlt = 0;
      var isCentered = false;

      if (lockedTarget != null) {
        var dAz = (lockedTarget.now.azimuth - _azimuth) % 360.0;
        if (dAz > 180) dAz -= 360;
        if (dAz < -180) dAz += 360;
        deltaAz = dAz;
        deltaAlt = lockedTarget.now.altitude - _altitude;
        isCentered = deltaAz.abs() < 4.0 && deltaAlt.abs() < 4.0;
      }

      return Scaffold(
        backgroundColor: _redMode ? const Color(0xFF100000) : AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(
                title: 'Point-to-Sky Compass',
                subtitle: 'Az ${_azimuth.toStringAsFixed(0)}° · Alt ${_altitude.toStringAsFixed(0)}° · Interactive AR',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Night-Vision Red Light',
                      icon: Icon(
                        Icons.brightness_medium_rounded,
                        color: _redMode ? AppColors.danger : AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _redMode = !_redMode),
                    ),
                    IconButton(
                      tooltip: 'Select Target',
                      icon: const Icon(
                        Icons.track_changes_rounded,
                        color: AppColors.secondary,
                      ),
                      onPressed: () => _showTargetPicker(context, controller),
                    ),
                  ],
                ),
              ),

              // Quick Controls Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Cardinal Directions quick jump buttons
                      ...[
                        ('N', 0.0),
                        ('E', 90.0),
                        ('S', 180.0),
                        ('W', 270.0),
                      ].map((c) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(c.$1, style: const TextStyle(fontSize: 11)),
                              onPressed: () => setState(() => _azimuth = c.$2),
                            ),
                          )),
                      ActionChip(
                        label: const Text('Zenith (90°)', style: TextStyle(fontSize: 11)),
                        onPressed: () => setState(() => _altitude = 89.0),
                      ),
                      const SizedBox(width: 6),
                      // Toggles
                      FilterChip(
                        label: const Text('Grid', style: TextStyle(fontSize: 11)),
                        selected: _showGrid,
                        onSelected: (v) => setState(() => _showGrid = v),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Labels', style: TextStyle(fontSize: 11)),
                        selected: _showLabels,
                        onSelected: (v) => setState(() => _showLabels = v),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: Text('FOV: $_fovPresetName', style: const TextStyle(fontSize: 11)),
                        onPressed: () => _showFovPicker(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive AR Viewport with Drag gesture
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Gesture Detector for drag looking around the sky
                        GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              // Sensitivity: 0.25 degrees per pixel
                              _azimuth = (_azimuth - details.delta.dx * 0.25) % 360.0;
                              if (_azimuth < 0) _azimuth += 360.0;
                              _altitude = (_altitude + details.delta.dy * 0.25)
                                  .clamp(-10.0, 90.0);
                            });
                          },
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _ArSkyPainter(
                              centerAz: _azimuth,
                              centerAlt: _altitude,
                              targets: targets,
                              lockedTargetId: _lockedTargetId,
                              showGrid: _showGrid,
                              showLabels: _showLabels,
                              showFov: _showFov,
                              fovH: _fovH,
                              fovV: _fovV,
                              redMode: _redMode,
                            ),
                          ),
                        ),

                        // Center Crosshair reticle
                        Center(
                          child: IgnorePointer(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCentered
                                      ? (Colors.greenAccent)
                                      : (_redMode
                                          ? AppColors.danger.withValues(alpha: 0.6)
                                          : AppColors.secondary.withValues(alpha: 0.6)),
                                  width: isCentered ? 2.5 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isCentered
                                        ? Colors.greenAccent
                                        : (_redMode ? AppColors.danger : AppColors.secondary),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Guidance Radar HUD Badge at top of viewport
                        if (lockedTarget != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: (isCentered
                                        ? const Color(0xFF0F392B)
                                        : (_redMode
                                            ? const Color(0xFF330808)
                                            : const Color(0xFF131D33)))
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCentered
                                      ? Colors.greenAccent
                                      : (_redMode ? AppColors.danger : AppColors.secondary),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCentered
                                        ? Icons.check_circle_rounded
                                        : Icons.radar_rounded,
                                    size: 18,
                                    color: isCentered
                                        ? Colors.greenAccent
                                        : (_redMode ? AppColors.danger : AppColors.secondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCentered
                                              ? 'TARGET CENTERED: ${lockedTarget.object.id} · ${lockedTarget.object.name}'
                                              : 'GUIDING TO ${lockedTarget.object.id} · ${lockedTarget.object.name}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isCentered
                                                ? Colors.greenAccent
                                                : (_redMode
                                                    ? AppColors.danger
                                                    : AppColors.textPrimary),
                                          ),
                                        ),
                                        Text(
                                          isCentered
                                              ? 'Alt ${lockedTarget.now.altitude.toStringAsFixed(1)}° · Az ${lockedTarget.now.azimuth.toStringAsFixed(1)}°'
                                              : '${deltaAz > 0 ? "▶ Turn Right" : "◀ Turn Left"} ${deltaAz.abs().toStringAsFixed(1)}° · ${deltaAlt > 0 ? "▲ Tilt Up" : "▼ Tilt Down"} ${deltaAlt.abs().toStringAsFixed(1)}°',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isCentered
                                                ? Colors.greenAccent
                                                : (_redMode
                                                    ? AppColors.danger
                                                    : AppColors.secondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () => _centerOnTarget(lockedTarget!),
                                    child: const Text('Center', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Bottom HUD coordinates bar
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (_redMode
                                      ? const Color(0xFF220505)
                                      : const Color(0xFF060A14))
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _redMode ? AppColors.danger : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Azimuth: ${_azimuth.toStringAsFixed(1)}° (${_compassHeading(_azimuth)})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _redMode ? AppColors.danger : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Altitude: ${_altitude.toStringAsFixed(1)}°',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _altitude >= 30
                                        ? AppColors.primary
                                        : (_redMode ? AppColors.danger : AppColors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  static String _compassHeading(double az) {
    const headings = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((az + 22.5) / 45.0).floor() % 8;
    return headings[idx];
  }
}

class _ArSkyPainter extends CustomPainter {
  _ArSkyPainter({
    required this.centerAz,
    required this.centerAlt,
    required this.targets,
    required this.lockedTargetId,
    required this.showGrid,
    required this.showLabels,
    required this.showFov,
    required this.fovH,
    required this.fovV,
    required this.redMode,
  });

  final double centerAz;
  final double centerAlt;
  final List<TargetPlan> targets;
  final String? lockedTargetId;
  final bool showGrid;
  final bool showLabels;
  final bool showFov;
  final double fovH;
  final double fovV;
  final bool redMode;

  // Viewport spans 60 degrees horizontally and 40 degrees vertically
  static const double viewSpanAz = 60.0;
  static const double viewSpanAlt = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background sky gradient
    final skyPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: redMode
            ? [const Color(0xFF1E0303), const Color(0xFF0A0101)]
            : [const Color(0xFF0F1B2F), const Color(0xFF050811)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Pixels per degree
    final pxPerDegX = size.width / viewSpanAz;
    final pxPerDegY = size.height / viewSpanAlt;

    // Helper: converts (az, alt) to (x, y) on canvas
    Offset? toCanvas(double az, double alt) {
      var dAz = (az - centerAz) % 360.0;
      if (dAz > 180) dAz -= 360;
      if (dAz < -180) dAz += 360;

      final dAlt = alt - centerAlt;

      final x = cx + dAz * pxPerDegX;
      final y = cy - dAlt * pxPerDegY;
      return Offset(x, y);
    }

    // 1. Draw Horizon Line and Ground Occlusion Mask
    final horizonY = cy + (centerAlt - 0.0) * pxPerDegY;
    if (horizonY < size.height) {
      // Ground below horizon
      final groundTop = math.max(0.0, horizonY);
      final groundHeight = size.height - groundTop;
      if (groundHeight > 0) {
        final groundPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: redMode
                ? [const Color(0xFF330A0A), const Color(0xFF150202)]
                : [const Color(0xFF111D1E), const Color(0xFF070B0B)],
          ).createShader(Rect.fromLTWH(0, groundTop, size.width, groundHeight));
        canvas.drawRect(
          Rect.fromLTWH(0, groundTop, size.width, groundHeight),
          groundPaint,
        );
      }

      // Horizon glowing border
      final horizPaint = Paint()
        ..color = redMode ? AppColors.danger : const Color(0xFF00E5FF)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(0, horizonY),
        Offset(size.width, horizonY),
        horizPaint,
      );

      final horizLabel = TextPainter(
        text: TextSpan(
          text: 'HORIZON (0° ALTITUDE)',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: redMode ? AppColors.danger : const Color(0xFF00E5FF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      horizLabel.paint(canvas, Offset(8, horizonY + 4));
    }

    // 2. Draw Altitude & Azimuth Grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = (redMode ? AppColors.danger : AppColors.border).withValues(alpha: 0.35)
        ..strokeWidth = 1.0;

      // Altitude lines (15°, 30°, 45°, 60°, 75°)
      for (final alt in [15.0, 30.0, 45.0, 60.0, 75.0]) {
        final y = cy - (alt - centerAlt) * pxPerDegY;
        if (y >= 0 && y <= size.height) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

          final label = TextPainter(
            text: TextSpan(
              text: '${alt.toInt()}°',
              style: TextStyle(
                fontSize: 9,
                color: (redMode ? AppColors.danger : AppColors.textSecondary)
                    .withValues(alpha: 0.7),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, Offset(6, y - 12));
        }
      }

      // Azimuth vertical lines every 15 degrees
      final startAz = ((centerAz - viewSpanAz / 2) / 15.0).floor() * 15;
      final endAz = ((centerAz + viewSpanAz / 2) / 15.0).ceil() * 15;

      for (var az = startAz; az <= endAz; az += 15) {
        final azNorm = (az % 360 + 360) % 360;
        final pt = toCanvas(azNorm.toDouble(), centerAlt);
        if (pt != null && pt.dx >= 0 && pt.dx <= size.width) {
          canvas.drawLine(Offset(pt.dx, 0), Offset(pt.dx, size.height), gridPaint);

          // Cardinal markings (N, NE, E, SE, S, SW, W, NW)
          String? cardinal;
          if (azNorm == 0) cardinal = 'N';
          if (azNorm == 45) cardinal = 'NE';
          if (azNorm == 90) cardinal = 'E';
          if (azNorm == 135) cardinal = 'SE';
          if (azNorm == 180) cardinal = 'S';
          if (azNorm == 225) cardinal = 'SW';
          if (azNorm == 270) cardinal = 'W';
          if (azNorm == 315) cardinal = 'NW';

          final txt = cardinal != null ? '$cardinal\n$azNorm°' : '$azNorm°';
          final label = TextPainter(
            text: TextSpan(
              text: txt,
              style: TextStyle(
                fontSize: 8,
                fontWeight: cardinal != null ? FontWeight.w800 : FontWeight.w500,
                color: cardinal != null
                    ? (redMode ? AppColors.danger : AppColors.secondary)
                    : (redMode ? AppColors.danger : AppColors.textSecondary)
                        .withValues(alpha: 0.6),
              ),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, Offset(pt.dx - label.width / 2, size.height - 24));
        }
      }
    }

    // 3. Draw Camera Sensor FOV Box in Center
    if (showFov) {
      final fovW = fovH * pxPerDegX;
      final fovHeightPx = fovV * pxPerDegY;
      final fovRect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: fovW,
        height: fovHeightPx,
      );

      final fovBorder = Paint()
        ..color = (redMode ? AppColors.danger : AppColors.secondary).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(fovRect, fovBorder);
    }

    // 4. Render Deep-Sky Objects & Planets in View
    for (final p in targets) {
      final pt = toCanvas(p.now.azimuth, p.now.altitude);
      if (pt == null) continue;

      // Check if inside canvas boundaries
      if (pt.dx < -20 || pt.dx > size.width + 20 || pt.dy < -20 || pt.dy > size.height + 20) {
        continue;
      }

      final isLocked = lockedTargetId == p.object.id;
      final isPlanet = p.object.isPlanet;

      // Color scheme
      Color objColor = redMode ? AppColors.danger : AppColors.secondary;
      if (isPlanet) {
        objColor = redMode ? AppColors.danger : AppColors.amber;
      } else if (p.object.type.contains('Nebula')) {
        objColor = redMode ? AppColors.danger : AppColors.violet;
      } else if (p.object.type.contains('Galaxy')) {
        objColor = redMode ? AppColors.danger : AppColors.primary;
      }

      if (isLocked) {
        // Glowing target ring
        final lockRing = Paint()
          ..color = (redMode ? AppColors.danger : Colors.greenAccent).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pt, 14, lockRing);
      }

      // Center dot or icon representation
      final dotPaint = Paint()..color = objColor;
      canvas.drawCircle(pt, isLocked ? 5.0 : 3.5, dotPaint);

      // Label
      if (showLabels) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${p.object.id}\n${p.object.name}',
            style: TextStyle(
              fontSize: isLocked ? 10 : 8,
              fontWeight: isLocked ? FontWeight.w800 : FontWeight.w600,
              color: isLocked
                  ? (redMode ? AppColors.danger : Colors.greenAccent)
                  : (redMode ? AppColors.danger : AppColors.textPrimary),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pt.dx + 6, pt.dy - 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArSkyPainter oldDelegate) => true;
}
