import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_title.dart';

class SunTwilightScreen extends StatelessWidget {
  const SunTwilightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
      (Icons.wb_sunny_outlined, 'Sunset', '6:22 PM', 'Sun crosses the horizon'),
      (Icons.light_mode_outlined, 'Civil twilight ends', '6:46 PM', 'Sun at -6°'),
      (Icons.brightness_5_outlined, 'Nautical twilight ends', '7:17 PM', 'Sun at -12°'),
      (Icons.dark_mode_outlined, 'Astronomical darkness', '7:49 PM', 'Sun at -18°'),
      (Icons.dark_mode_rounded, 'Astronomical dawn', '5:08 AM', 'Dark-sky window ends'),
      (Icons.wb_sunny_outlined, 'Sunrise', '6:31 AM', 'Next morning'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(title: 'Sun & twilight', subtitle: 'Offline solar calculations'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                backgroundColor: const Color(0xFF10162A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Darkness tonight', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    const Text('7:49 PM - 5:08 AM', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('9h 19m of astronomical darkness', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC46A), Color(0xFF56627C), Color(0xFF283451), Color(0xFF10162A), Color(0xFF10162A), Color(0xFF283451), Color(0xFF56627C), Color(0xFFFFC46A)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SectionTitle(title: 'Timeline')),
            const SizedBox(height: 10),
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)), child: Icon(event.$1, color: event.$2.contains('dark') || event.$2.contains('Astronomical') ? AppColors.primary : AppColors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.$2, style: const TextStyle(fontWeight: FontWeight.w700)), Text(event.$4, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
                      Text(event.$3, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
