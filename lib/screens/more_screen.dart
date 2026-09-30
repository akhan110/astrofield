import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.crop_free_rounded, 'Framing Simulator', 'Visual sensor FOV, rotation & target scale', AppRoutes.framingSimulator),
      (Icons.explore_rounded, 'Polar Alignment Clock', 'Polaris & Octans hour angle reticle', AppRoutes.polarAlignment),
      (Icons.timeline_rounded, 'Session Scheduler', 'Multi-target night sequence & darkness allocation', AppRoutes.sessionScheduler),
      (Icons.screen_rotation_rounded, 'Point-to-Sky Compass', 'Live compass & horizon mask AR mode', AppRoutes.pointToSky),
      (Icons.flashlight_on_rounded, 'Night Tools & Red Light', 'Dark adaptation, NPF star rule & dew point', AppRoutes.redLightTools),
      (Icons.location_on_outlined, 'Location & GPS', 'Current coordinates and observing site', AppRoutes.location),
      (Icons.cloud_outlined, 'Weather', 'Cached conditions and forecast', AppRoutes.weather),
      (Icons.brightness_3_outlined, 'Moon', 'Phase, illumination and moon times', AppRoutes.moon),
      (Icons.wb_twilight_outlined, 'Sun & twilight', 'Sunset and astronomical darkness', AppRoutes.sunTwilight),
      (Icons.camera_outlined, 'Equipment', 'Camera, telescope and field of view', AppRoutes.equipment),
      (Icons.download_for_offline_outlined, 'Offline trip pack', 'Prepare everything before travel', AppRoutes.tripPack),
      (Icons.sync_rounded, 'Sync center', 'Fresh data and local cache status', AppRoutes.sync),
      (Icons.settings_outlined, 'Settings', 'Units, thresholds and app preferences', AppRoutes.settings),
      (Icons.info_outline_rounded, 'About & data', 'Offline engine and source notes', AppRoutes.about),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Text('More', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text('Field tools and offline controls', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => Get.toNamed(item.$4),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)), child: Icon(item.$1, color: AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(item.$3, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
