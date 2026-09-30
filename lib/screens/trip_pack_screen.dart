import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class TripPackScreen extends StatefulWidget {
  const TripPackScreen({super.key});

  @override
  State<TripPackScreen> createState() => _TripPackScreenState();
}

class _TripPackScreenState extends State<TripPackScreen> {
  bool preparing = false;
  double progress = 1;

  Future<void> _prepare() async {
    setState(() {
      preparing = true;
      progress = .1;
    });
    for (final p in [.28, .46, .68, .86, 1.0]) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => progress = p);
    }
    if (mounted) setState(() => preparing = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.star_outline_rounded, 'Object catalog', '12,842 objects', true),
      (Icons.cloud_outlined, 'Weather forecast', '7 days cached', true),
      (Icons.brightness_3_outlined, 'Moon ephemeris', '90 days', true),
      (Icons.wb_twilight_outlined, 'Sun & twilight', 'Calculated locally', true),
      (Icons.travel_explore_rounded, 'Comets & bright asteroids', 'Last synced today', true),
      (Icons.map_outlined, 'Field site notes', '1 observing site', true),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(title: 'Offline trip pack', subtitle: 'Prepare the app before leaving coverage'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                backgroundColor: const Color(0xFF101830),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 58, height: 58, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .12), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.offline_pin_rounded, color: AppColors.success, size: 30)),
                        const SizedBox(width: 14),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Field-ready', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Core astronomy data is stored on this device.', style: TextStyle(color: AppColors.textSecondary))])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(10)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(preparing ? 'Preparing pack...' : 'Pack complete', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(item.$1, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(item.$3, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
                      Icon(item.$4 ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: item.$4 ? AppColors.success : AppColors.amber),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: preparing ? null : _prepare,
                  icon: const Icon(Icons.download_for_offline_rounded),
                  label: Text(preparing ? 'Preparing...' : 'Refresh offline pack'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
