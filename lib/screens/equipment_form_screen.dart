import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class EquipmentFormScreen extends StatelessWidget {
  const EquipmentFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
                title: 'Equipment setup', subtitle: 'UI prototype form'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const Text('Setup name',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const TextField(
                      decoration: InputDecoration(
                          hintText: 'e.g. Wide-field deep sky')),
                  const SizedBox(height: 18),
                  const Text('Camera',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.camera_alt_outlined),
                          hintText: 'Camera model')),
                  const SizedBox(height: 12),
                  // ignore: prefer_const_constructors
                  Row(children: const [
                    Expanded(
                        child: TextField(
                            decoration: InputDecoration(
                                labelText: 'Sensor width', suffixText: 'mm'),
                            keyboardType: TextInputType.number)),
                    SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            decoration: InputDecoration(
                                labelText: 'Sensor height', suffixText: 'mm'),
                            keyboardType: TextInputType.number))
                  ]),
                  const SizedBox(height: 18),
                  const Text('Optics',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.center_focus_strong_rounded),
                          hintText: 'Telescope / lens')),
                  const SizedBox(height: 12),
                  const Row(children: [
                    Expanded(
                        child: TextField(
                            decoration: InputDecoration(
                                labelText: 'Focal length', suffixText: 'mm'),
                            keyboardType: TextInputType.number)),
                    SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            decoration: InputDecoration(
                                labelText: 'Aperture', suffixText: 'mm'),
                            keyboardType: TextInputType.number))
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border)),
                    child: const Row(children: [
                      Icon(Icons.crop_free_rounded, color: AppColors.secondary),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'Field of view will be calculated automatically from sensor size and focal length.',
                              style: TextStyle(color: AppColors.textSecondary)))
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                      height: 52,
                      child: FilledButton(
                          onPressed: () => Get.back(),
                          child: const Text('Save setup'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
