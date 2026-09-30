import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/page_header.dart';
import '../widgets/section_title.dart';

class MoonScreen extends StatelessWidget {
  const MoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const PageHeader(
                title: 'Moon conditions',
                subtitle: 'Phase, position and imaging impact'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                backgroundColor: const Color(0xFF10162A),
                child: Row(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFFF0F1E8)),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                            width: 85,
                            height: 112,
                            decoration: const BoxDecoration(
                                color: Color(0xFF10162A),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(70),
                                    bottomLeft: Radius.circular(70)))),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Waxing Crescent',
                              style: TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text('17% illuminated',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 12),
                          Text('Favorable for deep-sky imaging after moonset.',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
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
                      icon: Icons.arrow_upward_rounded,
                      label: 'Moonrise',
                      value: '9:13 AM',
                      caption: 'Local time',
                      accent: AppColors.amber),
                  MetricTile(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Moonset',
                      value: '8:41 PM',
                      caption: 'Local time',
                      accent: AppColors.amber),
                  MetricTile(
                      icon: Icons.height_rounded,
                      label: 'Altitude now',
                      value: '8°',
                      caption: 'Low on horizon',
                      accent: AppColors.primary),
                  MetricTile(
                      icon: Icons.explore_rounded,
                      label: 'Azimuth',
                      value: '262° W',
                      caption: 'Current direction',
                      accent: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionTitle(
                    title: 'Target separation',
                    subtitle:
                        'Larger separation is usually better for faint targets')),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Column(
                  children: [
                    _MoonTarget(
                        name: 'M31 · Andromeda',
                        value: 103,
                        status: 'Excellent'),
                    Divider(height: 24),
                    _MoonTarget(name: 'M42 · Orion', value: 84, status: 'Good'),
                    Divider(height: 24),
                    _MoonTarget(
                        name: 'M45 · Pleiades', value: 67, status: 'Good'),
                    Divider(height: 24),
                    _MoonTarget(name: 'NGC 7000', value: 31, status: 'Fair'),
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

class _MoonTarget extends StatelessWidget {
  const _MoonTarget(
      {required this.name, required this.value, required this.status});
  final String name;
  final int value;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(status,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12))
      ])),
      Text('$value°',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))
    ]);
  }
}
