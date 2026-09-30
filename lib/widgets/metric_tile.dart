import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
