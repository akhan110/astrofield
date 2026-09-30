import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/field_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/page_header.dart';
import '../widgets/score_ring.dart';
import '../widgets/section_title.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(
                title: 'Weather cache', subtitle: 'Downloaded for offline use'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                backgroundColor: Color(0xFF101830),
                child: Row(
                  children: [
                    ScoreRing(
                        score: 88,
                        size: 86,
                        color: AppColors.secondary,
                        label: 'conditions'),
                    SizedBox(width: 18),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Excellent conditions',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                          SizedBox(height: 5),
                          Text(
                              'Mostly clear with light wind. Cached 47 min ago.',
                              style: TextStyle(color: AppColors.textSecondary)),
                          SizedBox(height: 7),
                          Row(children: [
                            Icon(Icons.offline_pin_rounded,
                                size: 16, color: AppColors.success),
                            SizedBox(width: 5),
                            Text('Available offline',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600))
                          ])
                        ])),
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
                children: const [
                  MetricTile(
                      icon: Icons.cloud_outlined,
                      label: 'Cloud cover',
                      value: '5%',
                      caption: 'Mostly clear',
                      accent: AppColors.secondary),
                  MetricTile(
                      icon: Icons.air_rounded,
                      label: 'Wind',
                      value: '6 km/h',
                      caption: 'Light breeze',
                      accent: AppColors.secondary),
                  MetricTile(
                      icon: Icons.water_drop_outlined,
                      label: 'Humidity',
                      value: '43%',
                      caption: 'Dew risk low',
                      accent: AppColors.primary),
                  MetricTile(
                      icon: Icons.thermostat_rounded,
                      label: 'Temperature',
                      value: '22°C',
                      caption: 'Falling to 16°C',
                      accent: AppColors.amber),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionTitle(title: 'Tonight hourly')),
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final c = Get.find<FieldController>();
              final hours = c.weather.value?.hours ?? [];
              if (hours.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Download weather when connected to view hourly forecast offline.',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return SizedBox(
                height: 152,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, i) {
                    final item = hours[i];
                    final t = item.time.toLocal();
                    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
                    final period = t.hour >= 12 ? 'PM' : 'AM';
                    return Container(
                      width: 94,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border)),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$hour12 $period',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            const Icon(Icons.cloud_queue_rounded,
                                color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text('${item.cloud?.round() ?? 0}% cloud',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('${item.temperature?.round() ?? 0}°C',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700))
                          ]),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemCount: hours.length,
                ),
              );
            }),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.amber),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Weather cannot update without internet. Astronomy calculations remain fully available offline.',
                          style: TextStyle(color: AppColors.textSecondary)))
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
