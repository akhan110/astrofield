import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_title.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sources = [
      (
        Icons.calculate_outlined,
        'Astronomy engine',
        'On-device position, rise/set, twilight and coordinate calculations.'
      ),
      (
        Icons.storage_rounded,
        'Local catalog',
        'Deep-sky object data stored locally for offline search and ranking.'
      ),
      (
        Icons.gps_fixed_rounded,
        'Device GNSS/GPS',
        'Observer latitude, longitude, altitude and accuracy from the device.'
      ),
      (
        Icons.cloud_outlined,
        'Weather provider',
        'Forecast is downloaded while online and clearly marked when cached.'
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(
                title: 'About AstroField',
                subtitle: 'Offline-first astrophotography planning'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                backgroundColor: const Color(0xFF101830),
                child: Column(
                  children: [
                    Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(24)),
                        child: const Icon(Icons.nights_stay_rounded,
                            size: 38, color: AppColors.primary)),
                    const SizedBox(height: 14),
                    const Text('AstroField',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('UI Prototype • v1.0.0',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    const Text(
                        'Built around one principle: core astronomy should continue working when the observing site has no internet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionTitle(title: 'Data architecture')),
            const SizedBox(height: 10),
            ...sources.map(
              (source) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(source.$1, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(source.$2,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(source.$3,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35))
                        ]))
                  ]),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppCard(
                child: Row(children: [
                  Icon(Icons.shield_outlined, color: AppColors.secondary),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'This prototype intentionally separates calculated astronomy from internet-dependent weather, so stale external data is never presented as live.',
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
