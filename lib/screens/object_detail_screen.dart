import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../controllers/favorites_controller.dart';
import '../data/catalog.dart';
import '../models/astro_target.dart';
import '../theme/app_theme.dart';
import '../widgets/altitude_chart.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/object_thumbnail.dart';
import '../widgets/page_header.dart';
import '../widgets/score_ring.dart';
import '../widgets/section_title.dart';

class ObjectDetailScreen extends StatelessWidget {
  const ObjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final target = Get.arguments is AstroTarget
        ? Get.arguments as AstroTarget
        : AstroTarget.fromCatalogObject(fieldCatalog.first);
    final favoritesController = Get.find<FavoritesController>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                PageHeader(
                  title: target.catalog,
                  subtitle: target.name,
                  trailing: Obx(() {
                    final isFavorite = favoritesController.isFavorite(target);
                    return IconButton.filledTonal(
                      tooltip: isFavorite ? 'Remove from saved' : 'Save target',
                      onPressed: () {
                        final isNowFavorite =
                            favoritesController.toggle(target);
                        Get.closeCurrentSnackbar();
                        Get.snackbar(
                          isNowFavorite ? 'Target saved' : 'Removed from saved',
                          '${target.catalog} ${target.name}',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: Icon(
                        isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AppCard(
                    backgroundColor: const Color(0xFF101830),
                    borderColor: target.accent.withValues(alpha: .35),
                    child: Row(
                      children: [
                        ObjectThumbnail(
                          catalog: target.catalog,
                          name: target.name,
                          size: 84,
                          borderRadius: 20,
                          accentColor: target.accent,
                          fallbackIcon: target.icon,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(target.name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 5),
                              Text('${target.type}  •  ${target.constellation}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 10),
                              const Row(children: [
                                Icon(Icons.circle,
                                    size: 9, color: AppColors.success),
                                SizedBox(width: 6),
                                Text('Visible now',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600))
                              ]),
                            ],
                          ),
                        ),
                        ScoreRing(
                            score: target.score,
                            size: 78,
                            color: target.accent,
                            label: 'score'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 34),
            sliver: SliverList.list(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    MetricTile(
                        icon: Icons.height_rounded,
                        label: 'Altitude',
                        value: '${target.altitude.toStringAsFixed(0)}°',
                        caption: 'High in the sky',
                        accent: target.accent),
                    MetricTile(
                        icon: Icons.explore_rounded,
                        label: 'Azimuth',
                        value: '148° ${target.azimuth}',
                        caption: 'Current direction',
                        accent: target.accent),
                    const MetricTile(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Rise',
                        value: '6:42 PM',
                        caption: 'Local time',
                        accent: AppColors.secondary),
                    const MetricTile(
                        icon: Icons.vertical_align_center_rounded,
                        label: 'Transit',
                        value: '11:57 PM',
                        caption: '73° peak altitude',
                        accent: AppColors.secondary),
                    const MetricTile(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Set',
                        value: '5:13 AM',
                        caption: 'Local time',
                        accent: AppColors.secondary),
                    MetricTile(
                        icon: Icons.star_outline_rounded,
                        label: 'Magnitude',
                        value: target.magnitude.toStringAsFixed(1),
                        caption: 'Apparent magnitude',
                        accent: AppColors.amber),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionTitle(
                    title: 'Altitude tonight',
                    subtitle: 'Estimated target altitude from 6:00 PM to 6:00 AM'),
                const SizedBox(height: 10),
                AppCard(
                    child: AltitudeChart(
                        accent: target.accent, peakAltitude: target.altitude)),
                const SizedBox(height: 20),
                const SectionTitle(title: 'Imaging window'),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: [
                      Row(children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Best time',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(target.bestWindow,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary))
                            ])),
                        Text(target.bestWindowDuration,
                            style: const TextStyle(fontWeight: FontWeight.w700))
                      ]),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _Reason(
                                icon: Icons.height_rounded,
                                title: 'High altitude',
                                text: target.altitude >= 60
                                    ? 'Strong'
                                    : target.altitude >= 30
                                        ? 'Fair'
                                        : 'Low')),
                        const Expanded(
                            child: _Reason(
                                icon: Icons.brightness_3_rounded,
                                title: 'Moon data',
                                text: 'Unavailable')),
                        const Expanded(
                            child: _Reason(
                                icon: Icons.dark_mode_rounded,
                                title: 'Darkness',
                                text: 'Unavailable'))
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle(title: 'Coordinates'),
                const SizedBox(height: 10),
                const AppCard(
                  child: Column(
                    children: [
                      _DataRow(
                          label: 'Right ascension', value: '05h 35m 17.3s'),
                      Divider(height: 24),
                      _DataRow(label: 'Declination', value: '-05° 23′ 28″'),
                      Divider(height: 24),
                      _DataRow(label: 'Constellation', value: 'Orion'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.skyChart),
                            icon: const Icon(Icons.public_rounded),
                            label: const Text('Locate in sky'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add to plan'))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 20, color: AppColors.secondary),
      const SizedBox(height: 7),
      Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 3),
      Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
    ]);
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
    ]);
  }
}
