import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (mounted) Get.offNamed(AppRoutes.shell);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-.4, -.5),
            radius: 1.15,
            colors: [Color(0xFF18254A), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColors.primary.withValues(alpha: .12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: .38)),
                ),
                child: const Icon(Icons.nights_stay_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('AstroField', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Your sky. Anywhere. Offline.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 54),
              const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ),
        ),
      ),
    );
  }
}
