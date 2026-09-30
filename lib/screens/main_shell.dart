import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/astro_drawer.dart';
import 'field_screens.dart';
import 'object_catalog_screen.dart';
import 'package:get/get.dart';
import '../controllers/object_catalog_controller.dart';
import 'home_screen.dart';
import 'more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    FieldScreen(FieldPage.sky, embedded: true),
    FieldScreen(FieldPage.tonight, embedded: true),
    ObjectCatalogScreen(savedOnly: true, embedded: true),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AstroDrawer(),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.midnightNavy.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1.2),
            left: BorderSide(color: AppColors.border, width: 1.0),
            right: BorderSide(color: AppColors.border, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.explore_outlined, 'Sky'),
                _navItem(2, Icons.auto_awesome, 'Tonight'),
                _navItem(3, Icons.bookmark_outline_rounded, 'Saved'),
                _navItem(4, Icons.grid_view_rounded, 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final isSelected = index == idx;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => index = idx);
          if (idx == 3 &&
              Get.isRegistered<ObjectCatalogController>(tag: 'savedCatalog')) {
            Get.find<ObjectCatalogController>(tag: 'savedCatalog').reload();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppColors.textPrimary,
                  size: 21,
                ),
              )
            else
              Icon(
                icon,
                color: AppColors.textMuted,
                size: 21,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            // Glowing white dot indicator under active tab
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
