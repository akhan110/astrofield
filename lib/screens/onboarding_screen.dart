import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int index = 0;

  static const pages = [
    (Icons.explore_rounded, 'Plan from anywhere', 'Object positions, rise/set times and darkness are calculated on-device using your GPS and time.'),
    (Icons.cloud_download_rounded, 'Sync before you leave', 'Download weather and fresh data while online, then keep planning when your field site has no signal.'),
    (Icons.camera_alt_rounded, 'Shoot the right target', 'Rank tonight’s objects by altitude, darkness, moon conditions, imaging window and your equipment.'),
  ];

  @override
  Widget build(BuildContext context) {
    final page = pages[index];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Get.offAllNamed(AppRoutes.shell), child: const Text('Skip')),
              ),
              const Spacer(),
              Container(
                width: 154,
                height: 154,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: .3), AppColors.surface]),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(page.$1, size: 68, color: AppColors.primary),
              ),
              const SizedBox(height: 42),
              Text(page.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              Text(page.$3, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.55)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    if (index == pages.length - 1) {
                      Get.offAllNamed(AppRoutes.shell);
                    } else {
                      setState(() => index++);
                    }
                  },
                  child: Text(index == pages.length - 1 ? 'Start planning' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
