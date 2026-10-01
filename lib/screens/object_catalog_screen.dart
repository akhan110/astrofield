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
  bool _showTip = true;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Cosmic header starry nebula & mountain silhouette backdrop
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 480,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/header_sky.png',
                  width: double.infinity,
                  height: 480,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.2),
                        AppColors.background.withValues(alpha: 0.85),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.45, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2. Main content list
          SafeArea(
            child: CustomScrollView(
              controller: scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top bar: Back/Home, Title, Subtitle, GPS Location
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xCC1A233D),
                                border: Border.all(
                                    color: const Color(0xFF2E3E68), width: 1.1),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Back',
                                onPressed: widget.embedded
                                    ? () => Get.offAllNamed(AppRoutes.shell)
                                    : () => Get.back(),
                                icon: const Icon(Icons.arrow_back_rounded,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.savedOnly
                                        ? 'Saved targets'
                                        : 'Object catalog',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Obx(
                                    () => Text(
                                      field.site.value?.name ??
                                          'Remote Dark-Sky Site',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xCC1A233D),
                                border: Border.all(
                                    color: const Color(0xFF2E3E68), width: 1.1),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Location',
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.location),
                                icon: const Icon(Icons.location_on_outlined,
                                    size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Date and Live clock pills
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _chooseTime(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC131532),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFF5A449B),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: Color(0xFFB0A4F5),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Obx(
                                          () => Text(
                                            '${clockTime(field.time.value)} · device time',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFD6D0FA),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                field.live.value = true;
                                field.time.value = DateTime.now().toUtc();
                                field.refresh();
                                c.reload();
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC0D1B3E),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF2E6FF2),
                                    width: 1.3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E6FF2)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: Color(0xFF82B1FF),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      field.live.value
                                          ? 'Live clock'
                                          : 'Return to now',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF82B1FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xCC0D162D),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF233258),
                              width: 1.2,
                            ),
                          ),
                          child: TextField(
                            controller: search,
                            onChanged: (v) {
                              c.setSearch(v);
                              setState(() {});
                            },
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: Color(0xFF82B1FF),
                              ),
                              hintText:
                                  'Catalog, name, alias, type, constellation...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF6B7D9E),
                                fontSize: 13,
                              ),
                              suffixIcon: search.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18, color: Color(0xFF8A9BB8)),
                                      onPressed: () {
                                        search.clear();
                                        c.setSearch('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Horizontally scrolling filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(
                            () => Row(
                              children: [
                                _menu<AstroObjectType?>(
                                  label: c.selectedType.value?.name ?? 'Type',
                                  icon: Icons.auto_awesome,
                                  isActive: c.selectedType.value != null,
                                  items: [null, ...AstroObjectType.values],
                                  text: (v) => v?.name ?? 'All types',
                                  onSelected: (v) {
                                    c.selectedType.value = v;
                                    c.reload();
                                  },
                                ),
                                const SizedBox(width: 8),
                                _menu<String?>(
                                  label: c.selectedConstellation.value ??
                                      'Constellation',
                                  icon: Icons.polyline_rounded,
                                  isActive:
                                      c.selectedConstellation.value != null,
                                  items: [null, ...c.constellations],
                                  text: (v) => v ?? 'All constellations',
                                  onSelected: (v) {
                                    c.selectedConstellation.value = v;
                                    c.reload();
                                  },
                                ),
                                const SizedBox(width: 8),
                                _menu<double?>(
                                  label: c.minAltitude.value == null
                                      ? 'Altitude'
                                      : '≥ ${c.minAltitude.value!.round()}°',
                                  icon: Icons.terrain_rounded,
                                  isActive: c.minAltitude.value != null,
                                  items: const [null, 0, 15, 30, 45, 60],
                                  text: (v) => v == null
                                      ? 'Any altitude'
                                      : '≥ ${v.round()}°',
                                  onSelected: (v) {
                                    c.minAltitude.value = v;
                                    c.reload();
                                  },
                                ),
                                const SizedBox(width: 8),
                                _menu<double?>(
                                  label: c.maxMagnitude.value == null
                                      ? 'Magnitude'
                                      : '≤ ${c.maxMagnitude.value}',
                                  icon: Icons.star_rounded,
                                  isActive: c.maxMagnitude.value != null,
                                  items: const [null, 6, 8, 10, 12, 14],
                                  text: (v) =>
                                      v == null ? 'Any magnitude' : '≤ $v',
                                  onSelected: (v) {
                                    c.maxMagnitude.value = v;
                                    c.reload();
                                  },
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    c.visibleNow.value = !c.visibleNow.value;
                                    c.reload();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: c.visibleNow.value
                                          ? const Color(0xCC1A1F52)
                                          : const Color(0xCC0E172F),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: c.visibleNow.value
                                            ? const Color(0xFF4C6EF5)
                                            : const Color(0xFF233258),
                                        width: 1.2,
                                      ),
                                      boxShadow: c.visibleNow.value
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF4C6EF5)
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 10,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.wb_sunny_rounded,
                                          size: 15,
                                          color: c.visibleNow.value
                                              ? const Color(0xFF82B1FF)
                                              : const Color(0xFF8FA0FF),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Visible now',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: c.visibleNow.value
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _menu<CatalogSort>(
                                  label: 'Sort: ${c.sort.value.name}',
                                  icon: Icons.sort_rounded,
                                  isActive: false,
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
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Object counter & per-page dropdown
                        Obx(
                          () => Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.total.value} objects',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (widget.savedOnly)
                                    const Text(
                                      'Saved catalog targets • available offline',
                                      style: TextStyle(
                                        color: Color(0xFF8A9BB8),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              PopupMenuButton<int>(
                                tooltip: 'Page size',
                                onSelected: (_) {},
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 50, child: Text('50 per page')),
                                  PopupMenuItem(
                                      value: 100, child: Text('100 per page')),
                                ],
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      c.visibleNow.value ||
                                              c.minAltitude.value != null
                                          ? 'Above selected altitude'
                                          : '50 per page',
                                      style: const TextStyle(
                                        color: Color(0xFF8A9BB8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.arrow_drop_down,
                                        size: 16, color: Color(0xFF8A9BB8)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // 3. Sliver List or Empty State
                Obx(() {
                  if (c.isLoading.value && c.objects.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (c.error.value.isNotEmpty && c.objects.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.error.value,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: c.initialize,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final items = c.objects.toList(growable: false);
                  if (items.isEmpty && !c.hasMore.value) {
                    if (widget.savedOnly) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptySavedState(),
                      );
                    }
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No matching objects. Try another designation or clear filters.',
                          style: TextStyle(color: Color(0xFF8A9BB8)),
                        ),
                      ),
                    );
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
                                    child: Text(
                                      c.isLoadingMore.value
                                          ? 'Loading…'
                                          : 'Load more',
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(height: 24);
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _row(items[i]),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySavedState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Glowing Bookmark Neon Badge with concentric orbital ripples
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ripple
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4C589F).withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                ),
                // Inner ripple
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7A64E0).withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7A64E0).withValues(alpha: 0.15),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                // Center Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCC1A1B44),
                    border: Border.all(
                      color: const Color(0xFF8E72FF),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E72FF).withValues(alpha: 0.45),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      size: 38,
                      color: Color(0xFFB49EFF),
                    ),
                  ),
                ),
                // Micro sparkles
                const Positioned(
                  top: 18,
                  left: 20,
                  child: Icon(Icons.auto_awesome,
                      size: 14, color: Color(0xFF7A88FF)),
                ),
                const Positioned(
                  bottom: 22,
                  right: 18,
                  child: Icon(Icons.auto_awesome,
                      size: 16, color: Color(0xFF00E5FF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No saved targets yet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save your favorite objects from the catalog\nto quickly plan and view them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8A9BB8),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              Get.toNamed(AppRoutes.search);
            },
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: const Text(
              'Explore catalog',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4361EE),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 6,
              shadowColor: const Color(0xFF4361EE).withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          // Tip card banner
          if (_showTip)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xCC0F162F),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF233258),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xCC2A2418),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFFFD54F),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tip',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Use the bookmark icon on any object in the catalog to save it for later. Saved targets are available offline.',
                          style: TextStyle(
                            color: Color(0xFF8A9BB8),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF8A9BB8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _showTip = false;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(AstroObject object) {
    SkyPosition? p;
    final site = field.site.value;
    if (site != null) {
      try {
        p = LocalAstronomyEngine()
            .positionForObject(object, site, field.time.value);
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC0D1427),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E2B4E),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Get.toNamed(AppRoutes.objectDetail, arguments: object.id),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ObjectThumbnail(
                  id: object.id,
                  catalog: object.designation,
                  name: object.displayName,
                  size: 46,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${object.designation} · ${object.displayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${object.type.name} · ${object.constellation ?? 'Unknown constellation'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A9BB8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${p == null ? 'Location needed' : '${p.altitude.toStringAsFixed(0)}° ${p.direction} • ${p.azimuth.toStringAsFixed(0)}°'}    ${object.magnitude == null ? 'Mag —' : 'Mag ${object.magnitude!.toStringAsFixed(1)}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF82B1FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => IconButton(
                    tooltip: c.savedIds.contains(object.id)
                        ? 'Remove from saved'
                        : 'Save target',
                    icon: Icon(
                      c.savedIds.contains(object.id)
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: c.savedIds.contains(object.id)
                          ? const Color(0xFF82B1FF)
                          : const Color(0xFF8A9BB8),
                      size: 22,
                    ),
                    onPressed: () => c.toggleSaved(object),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu<T>(
      {required String label,
      required IconData icon,
      required bool isActive,
      required List<T> items,
      required String Function(T) text,
      required void Function(T) onSelected}) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => items
          .map((e) => PopupMenuItem<T>(value: e, child: Text(text(e))))
          .toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xCC1A1F52) : const Color(0xCC0E172F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF4C6EF5) : const Color(0xFF233258),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4C6EF5).withValues(alpha: 0.35),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? const Color(0xFF82B1FF)
                  : const Color(0xFF8FA0FF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseTime(BuildContext context) async {
    final current = field.time.value.toLocal();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !context.mounted) return;
    field.time.value = DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    field.live.value = false;
    field.refresh();
    c.reload();
    setState(() {});
  }
}
