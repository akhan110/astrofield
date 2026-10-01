import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../models/astro_target.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'object_thumbnail.dart';
import 'score_ring.dart';

class TargetTile extends StatelessWidget {
  const TargetTile({
    super.key,
    required this.target,
    this.rank,
    this.isSaved,
    this.onSavedToggle,
  });

  final AstroTarget target;
  final int? rank;
  final bool? isSaved;
  final VoidCallback? onSavedToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Get.toNamed(AppRoutes.objectDetail, arguments: target),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (rank != null) ...[
            SizedBox(
              width: 30,
              child: Text(
                '${rank!}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary),
              ),
            ),
          ],
          ObjectThumbnail(
            catalog: target.catalog,
            name: target.name,
            size: 46,
            borderRadius: 14,
            accentColor: target.accent,
            fallbackIcon: target.icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(target.catalog,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        target.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${target.altitude.toStringAsFixed(0)}° ${target.azimuth}  •  ${target.bestWindow}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onSavedToggle != null) ...[
            IconButton(
              tooltip: isSaved == true ? 'Remove from saved' : 'Save target',
              onPressed: onSavedToggle,
              icon: Icon(
                isSaved == true
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              color: target.accent,
            ),
            const SizedBox(width: 2),
          ],
          ScoreRing(score: target.score, size: 52, color: target.accent),
        ],
      ),
    );
  }
}
