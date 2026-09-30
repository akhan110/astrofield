import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../data/catalog.dart';
import '../domain/field_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class SensorPreset {
  const SensorPreset(this.name, this.width, this.height, this.pixelSize);
  final String name;
  final double width, height, pixelSize;
}

class TelescopePreset {
  const TelescopePreset(this.name, this.focalLength);
  final String name;
  final double focalLength;
}

class FramingSimulatorScreen extends StatefulWidget {
  const FramingSimulatorScreen({super.key});

  @override
  State<FramingSimulatorScreen> createState() => _FramingSimulatorScreenState();
}

class _FramingSimulatorScreenState extends State<FramingSimulatorScreen> {
  late CatalogObject target;
  late double focalLength;
  late double sensorWidth;
  late double sensorHeight;
  late double pixelSize;
  double rotationDegrees = 0.0;

  static const sensorPresets = [
    SensorPreset('Full Frame (36×24)', 36.0, 24.0, 3.76),
    SensorPreset('APS-C / Crop (23.5×15.6)', 23.5, 15.6, 3.76),
    SensorPreset('Micro 4/3 (17.3×13)', 17.3, 13.0, 3.8),
    SensorPreset('ZWO ASI2600 (23.5×15.7)', 23.5, 15.7, 3.76),
    SensorPreset('ZWO ASI533 (11.3×11.3)', 11.31, 11.31, 3.76),
    SensorPreset('ZWO ASI183 (13.2×8.8)', 13.2, 8.8, 2.4),
    SensorPreset('ZWO ASI224 (4.8×3.6)', 4.8, 3.6, 3.75),
  ];

  static const telescopePresets = [
    TelescopePreset('135mm (Samyang / Rokinon)', 135.0),
    TelescopePreset('250mm (RedCat 51 / Short Refractor)', 250.0),
    TelescopePreset('350mm (Askar FRA400 f/3.9)', 350.0),
    TelescopePreset('480mm (80mm Triplet APO)', 480.0),
    TelescopePreset('600mm (Sky-Watcher Esprit 100)', 600.0),
    TelescopePreset('800mm (8" f/4 Astrograph)', 800.0),
    TelescopePreset('1000mm (8" f/5 Reflector)', 1000.0),
    TelescopePreset('2000mm (8" SCT / EdgeHD)', 2000.0),
  ];

  @override
  void initState() {
    super.initState();
    final c = Get.find<FieldController>();

    // Initial target from arguments or M42 / M31
    final initialId = Get.arguments is String ? Get.arguments as String : 'M42';
    target = fieldCatalog.firstWhere(
      (o) => o.id == initialId,
      orElse: () => fieldCatalog.first,
    );

    // Initial equipment from active equipment or default
    final activeEq = c.selectedEquipment;
    if (activeEq != null) {
      sensorWidth = activeEq.width;
      sensorHeight = activeEq.height;
      focalLength = activeEq.focalLength;
      pixelSize = activeEq.pixelSize;
    } else {
      sensorWidth = sensorPresets[1].width;
      sensorHeight = sensorPresets[1].height;
      focalLength = 250.0;
      pixelSize = 3.76;
    }
  }

  double get horizontalFov =>
      2 * math.atan(sensorWidth / (2 * focalLength)) * 180 / math.pi;

  double get verticalFov =>
      2 * math.atan(sensorHeight / (2 * focalLength)) * 180 / math.pi;

  double get diagonalFov =>
      2 *
      math.atan(math.sqrt(sensorWidth * sensorWidth + sensorHeight * sensorHeight) /
          (2 * focalLength)) *
      180 /
      math.pi;

  double get imageScale => 206.264806 * pixelSize / focalLength;

  String get samplingVerdict {
    final s = imageScale;
    if (s < 0.67) return 'Oversampled (high resolution, seeing limited)';
    if (s <= 2.0) return 'Optimal sampling (ideal star balance)';
    return 'Undersampled (sharp stars, great widefield coverage)';
  }

  Color get samplingColor {
    final s = imageScale;
    if (s < 0.67) return AppColors.amber;
    if (s <= 2.0) return AppColors.success;
    return AppColors.primary;
  }

  String get framingVerdict {
    if (target.sizeArcmin <= 0) return 'Angular size not cataloged';
    final targetDeg = target.sizeArcmin / 60.0;
    final minFov = math.min(horizontalFov, verticalFov);
    final maxFov = math.max(horizontalFov, verticalFov);

    if (targetDeg <= minFov * 0.8) {
      return 'Fits completely inside frame (single exposure)';
    } else if (targetDeg <= maxFov * 0.95) {
      return 'Fits with sensor rotation (${rotationDegrees.round()}°)';
    } else if (targetDeg <= diagonalFov * 1.05) {
      return 'Very tight framing — align diagonal carefully';
    } else {
      final panels = ((targetDeg / maxFov) * (targetDeg / minFov)).ceil().clamp(2, 8);
      return 'Target exceeds FOV — $panels-panel mosaic recommended';
    }
  }

  Color get framingColor {
    if (target.sizeArcmin <= 0) return AppColors.textSecondary;
    final targetDeg = target.sizeArcmin / 60.0;
    final minFov = math.min(horizontalFov, verticalFov);
    final maxFov = math.max(horizontalFov, verticalFov);

    if (targetDeg <= minFov * 0.8) return AppColors.success;
    if (targetDeg <= maxFov * 0.95) return AppColors.secondary;
    if (targetDeg <= diagonalFov * 1.05) return AppColors.amber;
    return AppColors.danger;
  }

  void _pickTarget() async {
    final selected = await showModalBottomSheet<CatalogObject>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TargetPickerSheet(currentTarget: target),
    );
    if (selected != null && mounted) {
      setState(() => target = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            PageHeader(
              title: 'Framing Simulator',
              subtitle: 'Sensor FOV & target scale visualizer',
              trailing: IconButton(
                tooltip: 'Target Details',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => Get.toNamed(
                  AppRoutes.objectDetail,
                  arguments: target.id,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Target Header Selector Card
                  AppCard(
                    onTap: _pickTarget,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            target.isPlanet
                                ? Icons.circle_outlined
                                : Icons.auto_awesome,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${target.id} · ${target.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${target.type} in ${target.constellation} • ${target.sizeArcmin > 0 ? "${target.sizeArcmin.toStringAsFixed(1)}' (${(target.sizeArcmin / 60).toStringAsFixed(2)}°)" : "Size N/A"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _pickTarget,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Visual Framing Canvas
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Visual Sensor Field of View',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${horizontalFov.toStringAsFixed(2)}° × ${verticalFov.toStringAsFixed(2)}°',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 280,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 5.0,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return CustomPaint(
                                    size: Size(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    ),
                                    painter: _FramingCanvasPainter(
                                      hFovDeg: horizontalFov,
                                      vFovDeg: verticalFov,
                                      targetSizeArcmin: target.sizeArcmin,
                                      targetName: target.id,
                                      targetType: target.type,
                                      rotationDegrees: rotationDegrees,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Camera Rotation Slider
                        Row(
                          children: [
                            const Icon(
                              Icons.rotate_right_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Camera Angle: ${rotationDegrees.round()}°',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: rotationDegrees,
                                min: 0.0,
                                max: 360.0,
                                divisions: 72,
                                label: '${rotationDegrees.round()}°',
                                onChanged: (v) =>
                                    setState(() => rotationDegrees = v),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => rotationDegrees = 0.0),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Framing Assessment Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: framingColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                framingVerdict,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: framingColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        Row(
                          children: [
                            Expanded(
                              child: _metricColumn(
                                'Image Scale',
                                '${imageScale.toStringAsFixed(2)} "/px',
                                samplingVerdict,
                                samplingColor,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _metricColumn(
                                'Target Diameter',
                                target.sizeArcmin > 0
                                    ? "${target.sizeArcmin.toStringAsFixed(1)}'"
                                    : 'Point source',
                                target.sizeArcmin > 0
                                    ? '${(target.sizeArcmin / 60).toStringAsFixed(2)}° in sky'
                                    : 'Sub-pixel',
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Equipment Presets & Custom Adjustments
                  const Text(
                    'Camera & Telescope Setup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Saved Equipment Quick Choice (if any)
                  if (c.equipment.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: c.equipment.map((eq) {
                          final isSelected = focalLength == eq.focalLength &&
                              sensorWidth == eq.width &&
                              sensorHeight == eq.height;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(eq.name),
                              avatar: const Icon(Icons.bookmark_rounded, size: 14),
                              backgroundColor: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.surface2,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              onPressed: () {
                                setState(() {
                                  focalLength = eq.focalLength;
                                  sensorWidth = eq.width;
                                  sensorHeight = eq.height;
                                  pixelSize = eq.pixelSize;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Sensor Preset Chips
                  const Text(
                    'Camera Sensor Presets',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: sensorPresets.map((s) {
                        final isSelected =
                            sensorWidth == s.width && sensorHeight == s.height;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(s.name),
                            selected: isSelected,
                            selectedColor:
                                AppColors.secondary.withValues(alpha: 0.25),
                            backgroundColor: AppColors.surface2,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  sensorWidth = s.width;
                                  sensorHeight = s.height;
                                  pixelSize = s.pixelSize;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Telescope Preset Chips
                  const Text(
                    'Focal Length Presets',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: telescopePresets.map((t) {
                        final isSelected = focalLength == t.focalLength;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t.name),
                            selected: isSelected,
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.25),
                            backgroundColor: AppColors.surface2,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  focalLength = t.focalLength;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Manual Sliders
                  AppCard(
                    child: Column(
                      children: [
                        _sliderRow(
                          label: 'Focal Length',
                          valueText: '${focalLength.round()} mm',
                          value: focalLength,
                          min: 50.0,
                          max: 2500.0,
                          divisions: 98,
                          onChanged: (v) => setState(() => focalLength = v),
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _sliderRow(
                          label: 'Sensor Width',
                          valueText: '${sensorWidth.toStringAsFixed(1)} mm',
                          value: sensorWidth,
                          min: 4.0,
                          max: 44.0,
                          divisions: 40,
                          onChanged: (v) => setState(() => sensorWidth = v),
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _sliderRow(
                          label: 'Sensor Height',
                          valueText: '${sensorHeight.toStringAsFixed(1)} mm',
                          value: sensorHeight,
                          min: 3.0,
                          max: 36.0,
                          divisions: 33,
                          onChanged: (v) => setState(() => sensorHeight = v),
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _sliderRow(
                          label: 'Pixel Pitch',
                          valueText: '${pixelSize.toStringAsFixed(2)} µm',
                          value: pixelSize,
                          min: 1.5,
                          max: 9.0,
                          divisions: 30,
                          onChanged: (v) => setState(() => pixelSize = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save Setup Button
                  FilledButton.icon(
                    onPressed: () {
                      final name =
                          'Rig (${focalLength.round()}mm • ${sensorWidth.toStringAsFixed(0)}×${sensorHeight.toStringAsFixed(0)})';
                      c.equipment.add(Equipment(
                        name,
                        sensorWidth,
                        sensorHeight,
                        focalLength,
                        pixelSize,
                      ));
                      c.persist();
                      Get.snackbar(
                        'Equipment Profile Saved',
                        'Added "$name" to your equipment profiles.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.surface2,
                        colorText: AppColors.textPrimary,
                      );
                    },
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: const Text('Save Setup to Equipment Profiles'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _metricColumn(
    String label,
    String value,
    String sub,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FramingCanvasPainter extends CustomPainter {
  _FramingCanvasPainter({
    required this.hFovDeg,
    required this.vFovDeg,
    required this.targetSizeArcmin,
    required this.targetName,
    required this.targetType,
    required this.rotationDegrees,
  });

  final double hFovDeg;
  final double vFovDeg;
  final double targetSizeArcmin;
  final String targetName;
  final String targetType;
  final double rotationDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Dark astronomical background
    final bgPaint = Paint()..color = const Color(0xFF070B16);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Circular background star/sky bowl reference
    final maxRadius = math.min(size.width, size.height) * 0.46;
    final skyBowlPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF131D33),
          Color(0xFF070B16),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, skyBowlPaint);

    // Subtle background field grid
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    // Scale mapping: the larger sensor dimension fits within ~72% of the canvas
    final maxFovDeg = math.max(hFovDeg, vFovDeg);
    final pxPerDegree = (maxRadius * 1.5) / maxFovDeg;

    final sensorW = hFovDeg * pxPerDegree;
    final sensorH = vFovDeg * pxPerDegree;

    // Apply Camera Rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDegrees * math.pi / 180.0);

    final sensorRect = Rect.fromCenter(
      center: Offset.zero,
      width: sensorW,
      height: sensorH,
    );

    // Fill sensor area
    final sensorAreaPaint = Paint()
      ..color = AppColors.surface2.withValues(alpha: 0.45);
    canvas.drawRect(sensorRect, sensorAreaPaint);

    // Rule of thirds lines inside sensor
    final thirdsPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(sensorRect.left + sensorW / 3, sensorRect.top),
      Offset(sensorRect.left + sensorW / 3, sensorRect.bottom),
      thirdsPaint,
    );
    canvas.drawLine(
      Offset(sensorRect.left + 2 * sensorW / 3, sensorRect.top),
      Offset(sensorRect.left + 2 * sensorW / 3, sensorRect.bottom),
      thirdsPaint,
    );
    canvas.drawLine(
      Offset(sensorRect.left, sensorRect.top + sensorH / 3),
      Offset(sensorRect.right, sensorRect.top + sensorH / 3),
      thirdsPaint,
    );
    canvas.drawLine(
      Offset(sensorRect.left, sensorRect.top + 2 * sensorH / 3),
      Offset(sensorRect.right, sensorRect.top + 2 * sensorH / 3),
      thirdsPaint,
    );

    // Sensor Border & Corner Accents
    final sensorBorderPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRect(sensorRect, sensorBorderPaint);

    // Sensor Top indicator arrow (North on camera sensor)
    final arrowPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, sensorRect.top - 12),
      Offset(0, sensorRect.top),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(-4, sensorRect.top - 7),
      Offset(0, sensorRect.top - 12),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(4, sensorRect.top - 7),
      Offset(0, sensorRect.top - 12),
      arrowPaint,
    );

    canvas.restore();

    // Draw Target Silhouette (Non-rotated celestial coordinate extent)
    final targetDeg = targetSizeArcmin / 60.0;
    final targetRadiusPx = math.max(4.0, (targetDeg / 2.0) * pxPerDegree);

    // Type color
    final isNebula = targetType.toLowerCase().contains('nebula');
    final isGalaxy = targetType.toLowerCase().contains('galaxy');
    final isCluster = targetType.toLowerCase().contains('cluster');
    final isPlanet = targetType == 'Planet';

    final targetColor = isNebula
        ? AppColors.secondary
        : isGalaxy
            ? AppColors.violet
            : isCluster
                ? AppColors.primary
                : isPlanet
                    ? AppColors.amber
                    : Colors.white;

    // Outer glow for target extent
    final targetGlowPaint = Paint()
      ..color = targetColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, targetRadiusPx, targetGlowPaint);

    // Target outline
    final targetOutlinePaint = Paint()
      ..color = targetColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (isGalaxy) {
      // Draw inclined ellipse for galaxies
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-35 * math.pi / 180);
      final ovalRect = Rect.fromCenter(
        center: Offset.zero,
        width: targetRadiusPx * 2,
        height: targetRadiusPx * 0.9,
      );
      canvas.drawOval(ovalRect, targetOutlinePaint);
      canvas.restore();
    } else {
      canvas.drawCircle(center, targetRadiusPx, targetOutlinePaint);
    }

    // Center Crosshair
    final centerCross = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.85)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), centerCross);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), centerCross);

    // Target Label in Center
    final tp = TextPainter(
      text: TextSpan(
        text: '$targetName (${targetSizeArcmin > 0 ? "${targetSizeArcmin.round()}'" : "Point"})',
        style: TextStyle(
          color: targetColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.black.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + targetRadiusPx + 4));

    // Dimension labels on sensor
    final dimPainter = TextPainter(textDirection: TextDirection.ltr);
    dimPainter.text = TextSpan(
      text: '${hFovDeg.toStringAsFixed(2)}° (${(hFovDeg * 60).round()}\')',
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    );
    dimPainter.layout();
    dimPainter.paint(canvas, Offset(16, size.height - 22));

    final rotPainter = TextPainter(
      text: TextSpan(
        text: 'Angle: ${rotationDegrees.round()}°',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    rotPainter.paint(canvas, Offset(size.width - rotPainter.width - 16, size.height - 22));
  }

  @override
  bool shouldRepaint(covariant _FramingCanvasPainter old) {
    return old.hFovDeg != hFovDeg ||
        old.vFovDeg != vFovDeg ||
        old.targetSizeArcmin != targetSizeArcmin ||
        old.targetName != targetName ||
        old.targetType != targetType ||
        old.rotationDegrees != rotationDegrees;
  }
}

class _TargetPickerSheet extends StatefulWidget {
  const _TargetPickerSheet({required this.currentTarget});
  final CatalogObject currentTarget;

  @override
  State<_TargetPickerSheet> createState() => _TargetPickerSheetState();
}

class _TargetPickerSheetState extends State<_TargetPickerSheet> {
  String search = '';
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final list = fieldCatalog.where((o) {
      if (category == 'Messier') {
        if (!RegExp(r'^M\d+$').hasMatch(o.id)) return false;
      } else if (category == 'Nebula') {
        if (!o.type.toLowerCase().contains('nebula')) return false;
      } else if (category == 'Galaxy') {
        if (!o.type.toLowerCase().contains('galaxy')) return false;
      } else if (category == 'Cluster') {
        if (!o.type.toLowerCase().contains('cluster')) return false;
      } else if (category == 'Planet') {
        if (o.type != 'Planet') return false;
      }

      final q = search.trim().toLowerCase();
      return q.isEmpty ||
          o.id.toLowerCase().contains(q) ||
          o.name.toLowerCase().contains(q) ||
          o.constellation.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Select Astro Target',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${list.length} objects',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search M31, Orion, Rosette, Jupiter...',
                isDense: true,
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: const [
                'All',
                'Messier',
                'Nebula',
                'Galaxy',
                'Cluster',
                'Planet'
              ].map((cat) {
                final isSelected = category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => category = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final item = list[i];
                final isCurrent = item.id == widget.currentTarget.id;
                return AppCard(
                  onTap: () => Navigator.of(context).pop(item),
                  child: Row(
                    children: [
                      Icon(
                        item.isPlanet ? Icons.circle_outlined : Icons.auto_awesome,
                        color: isCurrent ? AppColors.secondary : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.id} · ${item.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item.type} in ${item.constellation}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.sizeArcmin > 0
                              ? "${item.sizeArcmin.toStringAsFixed(1)}'"
                              : 'Point',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
