import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool syncing = false;

  Future<void> _sync() async {
    setState(() => syncing = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.cloud_outlined, 'Weather', '47 min ago', '7 days cached'),
      (Icons.travel_explore_rounded, 'Comets & asteroids', 'Today, 10:42', 'Up to date'),
      (Icons.star_outline_rounded, 'Deep-sky catalog', 'Sep 20', '12,842 objects'),
      (Icons.settings_input_antenna_rounded, 'Orbital elements', 'Today, 10:42', 'Up to date'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(title: 'Sync center', subtitle: 'Internet is used only for fresh external data'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                backgroundColor: const Color(0xFF101830),
                child: Row(
                  children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(syncing ? Icons.sync_rounded : Icons.wifi_rounded, color: AppColors.success)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(syncing ? 'Syncing fresh data' : 'Internet available', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(syncing ? 'Updating local cache...' : 'Safe to refresh your offline data', style: const TextStyle(color: AppColors.textSecondary))])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)), child: Icon(row.$1, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w700)), Text('Updated ${row.$3}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success), const SizedBox(height: 3), Text(row.$4, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(onPressed: syncing ? null : _sync, icon: const Icon(Icons.sync_rounded), label: Text(syncing ? 'Syncing...' : 'Sync now')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
