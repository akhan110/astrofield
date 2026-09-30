import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class SkyChartScreen extends StatefulWidget {
  const SkyChartScreen({super.key});

  @override
  State<SkyChartScreen> createState() => _SkyChartScreenState();
}

class _SkyChartScreenState extends State<SkyChartScreen> {
  bool labels = true;
  bool constellations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const PageHeader(
              title: 'Offline sky chart',
              subtitle: 'Horizon view • 11:42 PM local time'),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                    child: CustomPaint(
                        painter: _SkyPainter(
                            showLabels: labels,
                            showConstellations: constellations))),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 10,
                  child: Row(
                    children: [
                      _ToggleChip(
                          label: 'Labels',
                          selected: labels,
                          onTap: () => setState(() => labels = !labels)),
                      const SizedBox(width: 8),
                      _ToggleChip(
                          label: 'Constellations',
                          selected: constellations,
                          onTap: () =>
                              setState(() => constellations = !constellations)),
                      const Spacer(),
                      IconButton.filledTonal(
                          onPressed: () {},
                          icon: const Icon(Icons.my_location_rounded)),
                    ],
                  ),
                ),
                const Positioned(
                    left: 16, right: 16, bottom: 18, child: _CompassStrip()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
        label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _CompassStrip extends StatelessWidget {
  const _CompassStrip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('N', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('NE'),
            Text('E'),
            Text('SE'),
            Text('S', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('SW'),
            Text('W'),
            Text('NW')
          ]),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.showLabels, required this.showConstellations});
  final bool showLabels;
  final bool showConstellations;

  static const points = <Offset>[
    Offset(.12, .22),
    Offset(.18, .30),
    Offset(.28, .25),
    Offset(.34, .38),
    Offset(.45, .29),
    Offset(.55, .18),
    Offset(.61, .34),
    Offset(.70, .27),
    Offset(.79, .20),
    Offset(.88, .34),
    Offset(.14, .55),
    Offset(.23, .62),
    Offset(.35, .52),
    Offset(.46, .61),
    Offset(.56, .49),
    Offset(.67, .60),
    Offset(.78, .51),
    Offset(.86, .67),
    Offset(.31, .78),
    Offset(.51, .80),
    Offset(.71, .76),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF070A14);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = AppColors.border.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height * .52);
    for (final r in [size.width * .18, size.width * .34, size.width * .50]) {
      canvas.drawCircle(center, r.clamp(0, size.height * .42).toDouble(), grid);
    }
    canvas.drawLine(
        Offset(center.dx, 70), Offset(center.dx, size.height - 70), grid);
    canvas.drawLine(
        Offset(20, center.dy), Offset(size.width - 20, center.dy), grid);

    if (showConstellations) {
      final line = Paint()
        ..color = AppColors.primary.withValues(alpha: .22)
        ..strokeWidth = 1.2;
      const pairs = [
        (0, 1),
        (1, 2),
        (2, 3),
        (5, 6),
        (6, 7),
        (7, 8),
        (10, 11),
        (11, 12),
        (12, 13),
        (14, 15),
        (15, 16),
        (18, 19),
        (19, 20)
      ];
      for (final pair in pairs) {
        final a = Offset(
            points[pair.$1].dx * size.width, points[pair.$1].dy * size.height);
        final b = Offset(
            points[pair.$2].dx * size.width, points[pair.$2].dy * size.height);
        canvas.drawLine(a, b, line);
      }
    }

    final star = Paint()..color = AppColors.textPrimary;
    for (int i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx * size.width, points[i].dy * size.height);
      final radius = 1.3 + (i % 4) * .5;
      canvas.drawCircle(p, radius, star);
    }

    final targets = <(Offset, String, Color)>[
      (Offset(size.width * .35, size.height * .52), 'M42', AppColors.primary),
      (Offset(size.width * .67, size.height * .60), 'M31', AppColors.violet),
      (Offset(size.width * .23, size.height * .62), 'M45', AppColors.secondary),
      (Offset(size.width * .72, size.height * .35), 'Jupiter', AppColors.amber),
    ];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final item in targets) {
      final halo = Paint()..color = item.$3.withValues(alpha: .18);
      final dot = Paint()..color = item.$3;
      canvas.drawCircle(item.$1, 10, halo);
      canvas.drawCircle(item.$1, 4, dot);
      if (showLabels) {
        tp.text = TextSpan(
            text: item.$2,
            style: TextStyle(
                color: item.$3, fontSize: 11, fontWeight: FontWeight.w700));
        tp.layout();
        tp.paint(canvas, item.$1 + const Offset(9, -18));
      }
    }

    final horizon = Paint()
      ..color = const Color(0xFF11192A)
      ..style = PaintingStyle.fill;
    final hp = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * .88);
    for (double x = 0; x <= size.width; x += 12) {
      final y =
          size.height * .88 - math.sin(x / 45) * 10 - math.sin(x / 19) * 4;
      hp.lineTo(x, y);
    }
    hp.lineTo(size.width, size.height);
    hp.close();
    canvas.drawPath(hp, horizon);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.showLabels != showLabels ||
      oldDelegate.showConstellations != showConstellations;
}
