import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../controllers/object_catalog_controller.dart';
import '../data/astro_object_repository.dart';
import '../domain/field_models.dart';
import '../models/astro_object.dart';
import '../services/astronomy_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/object_thumbnail.dart';

class ObjectCatalogScreen extends StatefulWidget {
  const ObjectCatalogScreen(
      {super.key, this.savedOnly = false, this.embedded = false});
  final bool savedOnly, embedded;
  @override
  State<ObjectCatalogScreen> createState() => _ObjectCatalogScreenState();
}

class _ObjectCatalogScreenState extends State<ObjectCatalogScreen> {
  late final String tag = widget.savedOnly ? 'savedCatalog' : 'mainCatalog';
  late final ObjectCatalogController c =
      Get.put(ObjectCatalogController(savedOnly: widget.savedOnly), tag: tag);
  final field = Get.find<FieldController>();
  final scroll = ScrollController();
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.hasClients && scroll.position.extentAfter < 450) c.loadMore();
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    search.dispose();
    Get.delete<ObjectCatalogController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: CustomScrollView(controller: scroll, slivers: [
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        IconButton.filledTonal(
                            tooltip: 'Back',
                            onPressed: widget.embedded
                                ? () => Get.offAllNamed(AppRoutes.shell)
                                : () => Get.back(),
                            icon:
                                const Icon(Icons.arrow_back_ios_new, size: 17)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  widget.savedOnly
                                      ? 'Saved targets'
                                      : 'Object catalog',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Obx(() => Text(
                                  field.site.value?.name ?? 'No observing site',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)))
                            ])),
                        IconButton.filledTonal(
                            tooltip: 'GPS site',
                            onPressed: () => Get.toNamed(AppRoutes.location),
                            icon: const Icon(Icons.location_on_outlined))
                      ]),
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              color: AppColors.surface2,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Obx(() => Text(
                                    '${clockTime(field.time.value)} • device time',
                                    style: const TextStyle(fontSize: 12)))),
                            TextButton(
                                onPressed: () {
                                  field.live.value = true;
                                  field.time.value = DateTime.now().toUtc();
                                  field.refresh();
                                  setState(() {});
                                },
                                child: const Text('Live clock'))
                          ])),
                      const SizedBox(height: 8),
                      TextField(
                          controller: search,
                          onChanged: c.setSearch,
                          decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.primary),
                              hintText:
                                  'Catalog, name, alias, type, constellation',
                              suffixIcon: IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    search.clear();
                                    c.setSearch('');
                                  },
                                  icon: const Icon(Icons.clear)))),
                      const SizedBox(height: 8),
                      Obx(() => Wrap(spacing: 7, runSpacing: 6, children: [
                            _menu<AstroObjectType?>(
                                label: c.selectedType.value?.name ?? 'Type',
                                icon: Icons.auto_awesome,
                                items: [null, ...AstroObjectType.values],
                                text: (v) => v?.name ?? 'All types',
                                onSelected: (v) {
                                  c.selectedType.value = v;
                                  c.reload();
                                }),
                            _menu<String?>(
                                label: c.selectedConstellation.value ??
                                    'Constellation',
                                icon: Icons.polyline,
                                items: [null, ...c.constellations],
                                text: (v) => v ?? 'All constellations',
                                onSelected: (v) {
                                  c.selectedConstellation.value = v;
                                  c.reload();
                                }),
                            _menu<double?>(
                                label: c.minAltitude.value == null
                                    ? 'Altitude'
                                    : '≥ ${c.minAltitude.value!.round()}°',
                                icon: Icons.terrain_outlined,
                                items: const [null, 0, 15, 30, 45, 60],
                                text: (v) => v == null
                                    ? 'Any altitude'
                                    : '≥ ${v.round()}°',
                                onSelected: (v) {
                                  c.minAltitude.value = v;
                                  c.reload();
                                }),
                            _menu<double?>(
                                label: c.maxMagnitude.value == null
                                    ? 'Magnitude'
                                    : '≤ ${c.maxMagnitude.value}',
                                icon: Icons.star_outline,
                                items: const [null, 6, 8, 10, 12, 14],
                                text: (v) =>
                                    v == null ? 'Any magnitude' : '≤ $v',
                                onSelected: (v) {
                                  c.maxMagnitude.value = v;
                                  c.reload();
                                }),
                            FilterChip(
                                label: const Text('Visible now'),
                                selected: c.visibleNow.value,
                                onSelected: (v) {
                                  c.visibleNow.value = v;
                                  c.reload();
                                }),
                            _menu<CatalogSort>(
                                label: 'Sort: ${c.sort.value.name}',
                                icon: Icons.sort,
                                items: const [
                                  CatalogSort.designation,
                                  CatalogSort.name,
                                  CatalogSort.magnitude,
                                  CatalogSort.size,
                                  CatalogSort.altitude,
                                  CatalogSort.transit,
                                ],
                                text: (v) => v.name,
                                onSelected: (v) {
                                  c.sort.value = v;
                                  c.reload();
                                }),
                          ])),
                      const SizedBox(height: 8),
                      Obx(() => Row(children: [
                            Text('${c.total.value} objects',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                            const Spacer(),
                            Text(
                                c.visibleNow.value ||
                                        c.minAltitude.value != null
                                    ? 'Above selected altitude'
                                    : '50 per page',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11))
                          ])),
                      const Divider(height: 14),
                      if (widget.savedOnly)
                        const Text('Saved catalog targets • available offline',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                    ]))),
        Obx(() {
          if (c.isLoading.value && c.objects.isEmpty) {
            return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()));
          }
          if (c.error.value.isNotEmpty && c.objects.isEmpty) {
            return SliverFillRemaining(
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(c.error.value, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          OutlinedButton(
                              onPressed: c.initialize,
                              child: const Text('Retry'))
                        ]))));
          }
          final items = c.objects.toList(growable: false);
          if (items.isEmpty && !c.hasMore.value) {
            return const SliverFillRemaining(
                child: Center(
                    child: Text(
                        'No matching objects. Try another designation or clear filters.')));
          }
          return SliverList.builder(
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == items.length) {
                  return c.hasMore.value
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                              child: TextButton(
                                  onPressed: c.loadMore,
                                  child: Text(c.isLoadingMore.value
                                      ? 'Loading…'
                                      : 'Load more'))))
                      : const SizedBox(height: 20);
                }
                return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
                    child: _row(items[i]));
              });
        }),
      ])));

  Widget _row(AstroObject object) {
    SkyPosition? p;
    final site = field.site.value;
    if (site != null) {
      try {
        p = LocalAstronomyEngine()
            .positionForObject(object, site, field.time.value);
      } catch (_) {}
    }
    return InkWell(
        onTap: () => Get.toNamed(AppRoutes.objectDetail, arguments: object.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Row(children: [
              ObjectThumbnail(
                id: object.id,
                catalog: object.designation,
                name: object.displayName,
                size: 46,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${object.designation} · ${object.displayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                        '${object.type.name} · ${object.constellation ?? 'Unknown constellation'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 3),
                    Text(
                        '${p == null ? 'Location needed' : '${p.altitude.toStringAsFixed(0)}° ${p.direction} • ${p.azimuth.toStringAsFixed(0)}°'}    ${object.magnitude == null ? 'Mag —' : 'Mag ${object.magnitude!.toStringAsFixed(1)}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.primary))
                  ])),
              Obx(() => IconButton(
                  tooltip: c.savedIds.contains(object.id)
                      ? 'Remove from saved'
                      : 'Save target',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                      c.savedIds.contains(object.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 20,
                      color: AppColors.textPrimary),
                  onPressed: () => c.toggleSaved(object))),
            ])));
  }

  Widget _placeholder() => const ColoredBox(
      color: AppColors.surface2,
      child: Center(
          child: Icon(Icons.auto_awesome, size: 22, color: AppColors.primary)));
  Widget _menu<T>(
          {required String label,
          required IconData icon,
          required List<T> items,
          required String Function(T) text,
          required void Function(T) onSelected}) =>
      PopupMenuButton<T>(
          tooltip: label,
          onSelected: onSelected,
          itemBuilder: (context) => items
              .map((e) => PopupMenuItem<T>(value: e, child: Text(text(e))))
              .toList(),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(9),
                  color: AppColors.surface2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11)),
                const Icon(Icons.arrow_drop_down, size: 14)
              ])));
}
