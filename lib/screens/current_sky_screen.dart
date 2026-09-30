import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../data/catalog.dart';
import '../models/astro_target.dart';
import '../theme/app_theme.dart';
import '../widgets/target_tile.dart';

class CurrentSkyScreen extends StatefulWidget {
  const CurrentSkyScreen({super.key});

  @override
  State<CurrentSkyScreen> createState() => _CurrentSkyScreenState();
}

class _CurrentSkyScreenState extends State<CurrentSkyScreen> {
  String filter = 'All';
  final filters = const ['All', 'Nebulae', 'Galaxies', 'Clusters', 'Planets'];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final computed = c.targets().where((t) => t.now.altitude > 0).toList();
          var list = computed.isNotEmpty
              ? computed.map((t) => AstroTarget.fromTargetPlan(t)).toList()
              : fieldCatalog.map((o) => AstroTarget.fromCatalogObject(o)).toList();

          if (filter != 'All') {
            final f = filter.toLowerCase();
            list = list.where((t) {
              final ty = t.type.toLowerCase();
              if (f == 'nebulae') return ty.contains('nebula');
              if (f == 'galaxies') return ty.contains('galaxy');
              if (f == 'clusters') return ty.contains('cluster');
              if (f == 'planets') return ty.contains('planet');
              return true;
            }).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Current sky',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 2),
                          const Text('Objects above your horizon right now',
                              style: TextStyle(color: AppColors.textSecondary))
                        ])),
                    IconButton.filledTonal(
                        onPressed: () => Get.toNamed(AppRoutes.search),
                        icon: const Icon(Icons.search_rounded)),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                        onPressed: () => Get.toNamed(AppRoutes.skyChart),
                        icon: const Icon(Icons.public_rounded)),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) => ChoiceChip(
                      label: Text(filters[i]),
                      selected: filter == filters[i],
                      onSelected: (_) => setState(() => filter = filters[i])),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: filters.length,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  itemBuilder: (_, i) =>
                      TargetTile(target: list[i], rank: i + 1),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: list.length,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
