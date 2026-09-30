import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../theme/app_theme.dart';

class AstroDrawer extends StatelessWidget {
  const AstroDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Obx(() {
          final r = c.report.value;
          final siteName = c.site.value?.name ?? 'No site set';
          final moonIllum = r != null ? (r.moonIllumination * 100).round() : null;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface2,
                      AppColors.surface,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AstroField',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                'Offline Astrophotography',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            siteName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (moonIllum != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Moon $moonIllum%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Drawer List Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Astrophotography Tools Section
                    _sectionHeader('ASTRO TOOLS'),
                    _drawerTile(
                      icon: Icons.crop_free_rounded,
                      title: 'Framing Simulator',
                      subtitle: 'Visual sensor FOV & target fit',
                      highlightColor: AppColors.secondary,
                      badge: 'NEW',
                      badgeColor: AppColors.secondary,
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.framingSimulator);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.explore_rounded,
                      title: 'Polar Alignment Clock',
                      subtitle: 'Polaris & Octans hour angle reticle',
                      highlightColor: AppColors.primary,
                      badge: 'NEW',
                      badgeColor: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.polarAlignment);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.timeline_rounded,
                      title: 'Session Scheduler',
                      subtitle: 'Multi-target night timeline',
                      highlightColor: AppColors.violet,
                      badge: 'NEW',
                      badgeColor: AppColors.violet,
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.sessionScheduler);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.screen_rotation_rounded,
                      title: 'Point-to-Sky AR Mode',
                      subtitle: 'Live compass & horizon mask',
                      highlightColor: AppColors.amber,
                      badge: 'NEW',
                      badgeColor: AppColors.amber,
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.pointToSky);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.flashlight_on_rounded,
                      title: 'Night-Vision Red Light',
                      subtitle: 'Dark adapted screen & NPF rule',
                      highlightColor: AppColors.danger,
                      badge: 'NEW',
                      badgeColor: AppColors.danger,
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.redLightTools);
                      },
                    ),

                    const Divider(color: AppColors.border, height: 24),

                    // Core Planning Section
                    _sectionHeader('FIELD PLANNING'),
                    _drawerTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Equipment Profiles',
                      subtitle: 'Sensors, telescopes & lenses',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.equipment);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.search_rounded,
                      title: '207-Object Catalog',
                      subtitle: 'Messier, NGC, IC, Planets, Stars',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.search);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.cloud_outlined,
                      title: 'Weather Forecast',
                      subtitle: 'Offline cached conditions',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.weather);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.brightness_3_outlined,
                      title: 'Moon Conditions',
                      subtitle: 'Phases, rise/set & separation',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.moon);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.wb_twilight_outlined,
                      title: 'Sun & Twilight',
                      subtitle: 'Dusk, dawn & darkness windows',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.sunTwilight);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.location_on_outlined,
                      title: 'Observing Site & GPS',
                      subtitle: 'Set coordinates & elevation',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.location);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.download_for_offline_outlined,
                      title: 'Offline Trip Pack',
                      subtitle: 'Verify data readiness for field',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.tripPack);
                      },
                    ),
                    _drawerTile(
                      icon: Icons.settings_outlined,
                      title: 'App Settings',
                      subtitle: 'Thresholds, units, red mode',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppRoutes.settings);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  static Widget _drawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? highlightColor,
    String? badge,
    Color? badgeColor,
  }) {
    final color = highlightColor ?? AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.secondary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (badgeColor ?? AppColors.secondary).withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: badgeColor ?? AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}
