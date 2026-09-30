import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/section_title.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Get.toNamed(AppRoutes.equipmentForm), icon: const Icon(Icons.add_rounded), label: const Text('Add setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const PageHeader(title: 'Equipment', subtitle: 'Use your real setup to rank and frame targets'),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SectionTitle(title: 'Active setup')),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                borderColor: AppColors.primary.withValues(alpha: .5),
                backgroundColor: const Color(0xFF101830),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.camera_alt_rounded, color: AppColors.primary), SizedBox(width: 8), Expanded(child: Text('Wide-field deep sky', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Icon(Icons.check_circle_rounded, color: AppColors.success)]),
                    const SizedBox(height: 16),
                    const _EquipmentRow(label: 'Camera', value: 'Canon EOS R6'),
                    const Divider(height: 24),
                    const _EquipmentRow(label: 'Telescope', value: 'RedCat 51'),
                    const Divider(height: 24),
                    const _EquipmentRow(label: 'Focal length', value: '250 mm'),
                    const Divider(height: 24),
                    const _EquipmentRow(label: 'Sensor', value: '36 × 24 mm'),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.crop_free_rounded, color: AppColors.secondary), SizedBox(width: 10), Expanded(child: Text('Estimated field of view', style: TextStyle(color: AppColors.textSecondary))), Text('8.2° × 5.5°', style: TextStyle(fontWeight: FontWeight.w800))])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SectionTitle(title: 'Saved setups')),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                onTap: () => Get.toNamed(AppRoutes.equipmentForm),
                padding: const EdgeInsets.all(14),
                child: const Row(children: [Icon(Icons.camera_outlined, color: AppColors.violet), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Planetary setup', style: TextStyle(fontWeight: FontWeight.w700)), Text('ASI585MC • 1500 mm', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))])), Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]);
}
