import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/field_controller.dart';
import '../data/catalog.dart';
import '../models/astro_target.dart';
import '../theme/app_theme.dart';
import '../widgets/altitude_chart.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';
import '../widgets/target_tile.dart';

class TonightScreen extends StatelessWidget {
  const TonightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final planned = c.targets(tonight: true);
          final displayTargets = planned.isNotEmpty
              ? planned.take(6).map((t) => AstroTarget.fromTargetPlan(t)).toList()
              : fieldCatalog.take(6).map((o) => AstroTarget.fromCatalogObject(o)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              Text('Tonight', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text('Your imaging plan for the full night', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.wb_twilight_rounded, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text('Dark-sky window', style: TextStyle(fontWeight: FontWeight.w700)),
                      Spacer(),
                      Text('Astronomical darkness', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700))
                    ]),
                    const SizedBox(height: 16),
                    Container(height: 10, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [Color(0xFF59627C), Color(0xFF263353), Color(0xFF10172C), Color(0xFF10172C), Color(0xFF263353), Color(0xFF59627C)]))),
                    const SizedBox(height: 8),
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Sunset', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('Dusk', style: TextStyle(fontSize: 11)),
                      Text('Dawn', style: TextStyle(fontSize: 11)),
                      Text('Sunrise', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle(title: 'Night altitude overview', subtitle: 'Target curve calculated from your observing site'),
              const SizedBox(height: 10),
              AppCard(child: AltitudeChart(peakAltitude: displayTargets.isNotEmpty ? displayTargets.first.altitude : 60)),
              const SizedBox(height: 22),
              const SectionTitle(title: 'Best sequence', subtitle: 'Sorted by strongest imaging windows'),
              const SizedBox(height: 12),
              ...displayTargets.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TargetTile(target: entry.value, rank: entry.key + 1))),
            ],
          );
        }),
      ),
    );
  }
}
