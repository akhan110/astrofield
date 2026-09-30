import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/field_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/page_header.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final s = c.site.value;
          final lat = s != null ? '${s.latitude.abs().toStringAsFixed(4)}° ${s.latitude >= 0 ? "N" : "S"}' : '—';
          final lon = s != null ? '${s.longitude.abs().toStringAsFixed(4)}° ${s.longitude >= 0 ? "E" : "W"}' : '—';
          final elev = s != null ? '${s.elevation.round()} m' : '—';
          return ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              const PageHeader(title: 'Location & GPS', subtitle: 'Works without mobile data'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  backgroundColor: const Color(0xFF101830),
                  child: Column(
                    children: [
                      Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: .12),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.gps_fixed_rounded,
                              size: 34, color: AppColors.secondary)),
                      const SizedBox(height: 14),
                      Text(s != null ? 'Observing site set' : 'Location required',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(s?.name ?? 'Set your location',
                          style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: s != null ? AppColors.success : AppColors.amber),
                        const SizedBox(width: 6),
                        Text(s != null ? 'Offline position available' : 'Waiting for GPS fix',
                            style: TextStyle(
                                color: s != null ? AppColors.success : AppColors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    MetricTile(icon: Icons.north_rounded, label: 'Latitude', value: lat, caption: 'WGS84'),
                    MetricTile(icon: Icons.east_rounded, label: 'Longitude', value: lon, caption: 'WGS84'),
                    MetricTile(icon: Icons.landscape_outlined, label: 'Altitude', value: elev, caption: 'GPS estimate'),
                    MetricTile(icon: Icons.gps_fixed_rounded, label: 'Status', value: c.locating.value ? 'Acquiring…' : 'Ready', caption: 'On-device', accent: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Observing location', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(color: const Color(0xFF0A1220), borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          children: [
                            Positioned.fill(child: CustomPaint(painter: _MiniMapPainter())),
                            const Center(child: Icon(Icons.location_on_rounded, size: 38, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                              onPressed: c.locating.value ? null : c.gps,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(c.locating.value ? 'Acquiring GPS…' : 'Refresh GPS fix'))),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = AppColors.border.withValues(alpha: .6)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final road = Paint()..color = AppColors.primary.withValues(alpha: .17)..strokeWidth = 7..style = PaintingStyle.stroke;
    final path = Path()..moveTo(-10, size.height * .7)..quadraticBezierTo(size.width * .35, size.height * .3, size.width + 10, size.height * .55);
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
