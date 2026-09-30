import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/target_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FavoritesController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved targets',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        const Text('Objects you want to revisit',
                            style: TextStyle(color: AppColors.textSecondary))
                      ])),
            ),
            Expanded(
              child: Obx(() {
                final favorites = controller.favorites;
                if (favorites.isEmpty) {
                  return const _EmptyFavorites();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  itemBuilder: (_, i) {
                    final target = favorites[i];
                    return TargetTile(
                      target: target,
                      isSaved: true,
                      onSavedToggle: () {
                        controller.setFavorite(target, false);
                        Get.closeCurrentSnackbar();
                        Get.snackbar(
                          'Removed from saved',
                          '${target.catalog} ${target.name}',
                          snackPosition: SnackPosition.BOTTOM,
                          mainButton: TextButton(
                            onPressed: () {
                              controller.setFavorite(target, true);
                              Get.closeCurrentSnackbar();
                            },
                            child: const Text('UNDO'),
                          ),
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: favorites.length,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, 16, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No saved targets',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'Bookmark an object to find it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
