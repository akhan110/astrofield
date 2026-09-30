import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool metric = true;
  bool redMode = false;
  bool showBelow30 = false;
  bool autoSyncWifi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(
                title: 'Settings',
                subtitle: 'Offline behavior and observing preferences'),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionTitle(title: 'Observing')),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Metric units'),
                        subtitle: const Text('km/h, °C and meters',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        value: metric,
                        onChanged: (value) => setState(() => metric = value)),
                    const Divider(),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Red light mode'),
                        subtitle: const Text(
                            'Preserve dark adaptation in the field',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        value: redMode,
                        onChanged: (value) => setState(() => redMode = value)),
                    const Divider(),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show low-altitude targets'),
                        subtitle: const Text(
                            'Include objects below 30° altitude',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        value: showBelow30,
                        onChanged: (value) =>
                            setState(() => showBelow30 = value)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionTitle(title: 'Sync')),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto-sync on Wi-Fi'),
                        subtitle: const Text(
                            'Refresh weather and orbital data automatically',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        value: autoSyncWifi,
                        onChanged: (value) =>
                            setState(() => autoSyncWifi = value)),
                    const Divider(),
                    const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.download_for_offline_outlined,
                            color: AppColors.primary),
                        title: Text('Offline storage'),
                        subtitle: Text('184 MB used',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right_rounded)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionTitle(title: 'App')),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Column(
                  children: [
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary),
                        title: const Text('About & data sources'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Get.toNamed(AppRoutes.about)),
                    const Divider(),
                    const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.privacy_tip_outlined,
                            color: AppColors.primary),
                        title: Text('Privacy'),
                        subtitle: Text(
                            'Designed to keep core observing data on-device',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
