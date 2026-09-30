import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/field_controller.dart';
import '../data/catalog.dart';
import '../models/astro_target.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/target_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Messier',
    'Nebula',
    'Galaxy',
    'Cluster',
    'Planet',
    'Star',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FieldController>();
    final report = c.report.value;
    final allTargets = report != null
        ? report.targets.map((t) => AstroTarget.fromTargetPlan(t)).toList()
        : fieldCatalog.map((o) => AstroTarget.fromCatalogObject(o)).toList();

    final List<AstroTarget> results = allTargets.where((target) {
      // Category filter
      if (selectedFilter == 'Messier') {
        if (!RegExp(r'^M\d+$').hasMatch(target.catalog)) return false;
      } else if (selectedFilter == 'Nebula') {
        if (!target.type.toLowerCase().contains('nebula')) return false;
      } else if (selectedFilter == 'Galaxy') {
        if (!target.type.toLowerCase().contains('galaxy')) return false;
      } else if (selectedFilter == 'Cluster') {
        if (!target.type.toLowerCase().contains('cluster')) return false;
      } else if (selectedFilter == 'Planet') {
        if (target.type != 'Planet') return false;
      } else if (selectedFilter == 'Star') {
        if (target.type != 'Star') return false;
      }

      // Text search
      final q = query.trim().toLowerCase();
      return q.isEmpty ||
          target.catalog.toLowerCase().contains(q) ||
          target.name.toLowerCase().contains(q) ||
          target.constellation.toLowerCase().contains(q) ||
          target.type.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(
                title: 'Search objects',
                subtitle: 'Catalog, name, constellation or type'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: TextField(
                autofocus: false,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => query = ''),
                        )
                      : null,
                  hintText: 'M42, Andromeda, Orion, NGC 7000...',
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: filters.map((f) {
                  final isSelected = selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surface2,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => selectedFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${results.length} objects',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text('No matching objects',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                      itemBuilder: (_, i) => TargetTile(target: results[i]),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: results.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
