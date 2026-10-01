import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../data/astro_object_repository.dart';
import '../domain/field_models.dart';
import '../models/astro_object.dart';
import '../services/astronomy_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/object_thumbnail.dart';
import 'field_screens.dart';

class _Data {
  const _Data(this.object, this.report, this.saved);
  final AstroObject object;
  final NightReport? report;
  final bool saved;
}

class _Request {
  const _Request(this.object, this.site, this.time, this.minimum);
  final AstroObject object;
  final Site site;
  final DateTime time;
  final double minimum;
}

NightReport _calculate(_Request r) {
  final o = r.object;
  final target = CatalogObject(
    o.designation,
    o.displayName,
    o.type.name,
    ra: o.raDeg / 15,
    dec: o.decDeg,
    sizeArcmin: o.majorAxisArcmin ?? 0,
    magnitude: o.magnitude,
    constellation: o.constellation ?? '',
  );
  return LocalAstronomyEngine()
      .calculateFor(r.site, r.time, r.minimum, [target]);
}

class CatalogDetailScreen extends StatefulWidget {
  const CatalogDetailScreen({super.key});

  @override
  State<CatalogDetailScreen> createState() => _CatalogDetailScreenState();
}

class _CatalogDetailScreenState extends State<CatalogDetailScreen> {
  final field = Get.find<FieldController>();
  Future<_Data>? future;
  String? cacheKey;
  bool? savedOverride;

  Future<_Data> _load(
      String id, Site? site, DateTime time, double minimum) async {
    final repo = await AstroObjectRepository.shared();
    final object = await repo.getById(id);
    if (object == null) throw StateError('Object not found in local catalog');
    final saved = await repo.isFavorite(object.id);
    final report = site == null
        ? null
        : await compute(_calculate, _Request(object, site, time, minimum));
    return _Data(object, report, saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: SafeArea(
        child: Obx(() {
          final site = field.site.value,
              time = field.time.value,
              minimum = field.minimumAltitude.value;
          final id =
              Get.arguments is String ? Get.arguments as String : 'M1';
          final key =
              '$id:${site?.latitude}:${site?.longitude}:${time.millisecondsSinceEpoch ~/ 60000}:$minimum';
          if (cacheKey != key) {
            cacheKey = key;
            future = _load(id, site, time, minimum);
            savedOverride = null;
          }

          return FutureBuilder<_Data>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() => cacheKey = null),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                );
              }

              final data = snapshot.data!,
                  o = data.object,
                  r = data.report,
                  t = r?.targets.single,
                  saved = savedOverride ?? data.saved;

              final thumbnailPath = resolveObjectThumbnail(
                    id: o.id,
                    catalog: o.designation,
                    name: o.displayName,
                  ) ??
                  (RegExp(r'^M\d+$').hasMatch(o.designation)
                      ? 'assets/catalog/thumbnails/${o.designation}.jpg'
                      : null);

              final aliases = o.identifiers.isNotEmpty
                  ? o.identifiers.map((e) => e.designation).toList()
                  : o.aliases;

              return Column(
                children: [
                  // 1. Top App Bar
                  _buildTopBar(o, saved),

                  // 2. Scrollable Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        // Hero Image Banner
                        _buildHeroBanner(o, thumbnailPath, aliases),

                        const SizedBox(height: 12),

                        // Object Summary Card
                        _buildSummaryCard(o, thumbnailPath, aliases, saved),

                        const SizedBox(height: 12),

                        // Catalog coordinates
                        _buildCoordinatesCard(o),

                        const SizedBox(height: 12),

                        // Catalog properties
                        _buildPropertiesCard(o),

                        const SizedBox(height: 12),

                        // Live Observation Cards
                        if (t == null)
                          _buildCard(
                            icon: Icons.location_off_rounded,
                            iconColor: const Color(0xFF9FA8DA),
                            title: 'Observing site needed',
                            content: const Text(
                              'Set GPS or manual coordinates for live positions and tonight’s windows.',
                              style: TextStyle(color: Color(0xFF8A9BB8)),
                            ),
                          )
                        else ...[
                          // Position now (with 3D Radar Dial)
                          _buildPositionNowCard(t),

                          const SizedBox(height: 12),

                          // Tonight (with Peak Badge Altitude Chart)
                          _buildTonightCard(t),

                          const SizedBox(height: 12),

                          // Best imaging window
                          _buildBestWindowCard(t, minimum),

                          const SizedBox(height: 12),

                          // Moon Card (with 3D Moon and Separation Dial)
                          _buildMoonCard(r!, t),
                        ],

                        const SizedBox(height: 12),

                        // Equipment fit
                        _buildEquipmentFitCard(o),

                        const SizedBox(height: 12),

                        // Survey note
                        const Center(
                          child: Text(
                            'Images are real survey cutouts when available. Other targets use a placeholder.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7C98),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // 3. Bottom Action Bar
                  _buildBottomBar(o),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top App Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopBar(AstroObject o, bool saved) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xDD151B38),
                border: Border.all(color: const Color(0xFF2B3A64), width: 1.1),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Object Designation Title (e.g. M1, M27)
          Expanded(
            child: Text(
              o.designation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Bookmark Button
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save target',
            onPressed: () async {
              try {
                final repo = await AstroObjectRepository.shared();
                await repo.setFavorite(o.id, !saved);
                setState(() => savedOverride = !saved);
                if (field.favorites.contains(o.designation) == saved) {
                  field.toggleFavorite(o.designation);
                }
                Get.closeCurrentSnackbar();
                Get.snackbar(
                  !saved ? 'Saved target' : 'Removed from saved',
                  '${o.designation} • ${o.displayName}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (_) {
                Get.snackbar('Save failed', 'Could not update favorites.');
              }
            },
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: saved ? const Color(0xFF6C5CE7) : const Color(0xFFB0BEC5),
              size: 24,
            ),
          ),

          // Share Button
          IconButton(
            tooltip: 'Share',
            onPressed: () {
              Get.closeCurrentSnackbar();
              Get.snackbar(
                'Share Target',
                '${o.designation} (${o.displayName}) RA: ${o.raDeg.toStringAsFixed(2)}° Dec: ${o.decDeg.toStringAsFixed(2)}°',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(
              Icons.share_rounded,
              color: Color(0xFFB0BEC5),
              size: 22,
            ),
          ),

          // More Options Button
          IconButton(
            tooltip: 'Options',
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFFB0BEC5),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Image Banner with Overlaid Badges and Fullscreen Button
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner(
      AstroObject o, String? thumbnailPath, List<String> aliases) {
    final ngcAlias = aliases.firstWhere(
      (a) => a.contains('NGC') || a.contains('IC'),
      orElse: () => '',
    );

    return Container(
      height: 195,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1327),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF26355C), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Cosmic/Survey Image
          Positioned.fill(
            child: thumbnailPath != null
                ? Image.asset(
                    thumbnailPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/telescope_galaxy_art.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  )
                : Image.asset(
                    'assets/images/telescope_galaxy_art.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
          ),

          // Bottom Vignette / Shadow Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Overlaid Chips on Bottom-Left
          Positioned(
            left: 12,
            bottom: 12,
            child: Wrap(
              spacing: 6,
              children: [
                _pill(o.designation),
                if (ngcAlias.isNotEmpty) _pill(ngcAlias),
                _pill(o.displayName),
              ],
            ),
          ),

          // Fullscreen Expand Button on Bottom-Right
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xAA0D152C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF384A78).withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xCC0C142A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF324572), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Object Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard(AstroObject o, String? thumbnailPath,
      List<String> aliases, bool saved) {
    final subAliases = aliases.take(2).join(' • ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xDD0D152E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF26355C), width: 1.2),
      ),
      child: Row(
        children: [
          // Object Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              height: 58,
              color: const Color(0xFF060A16),
              child: thumbnailPath != null
                  ? Image.asset(
                      thumbnailPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF7C4DFF),
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF7C4DFF),
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Titles & Constellation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${o.type.name} • ${o.constellation ?? 'Constellation unavailable'}',
                  style: const TextStyle(
                    color: Color(0xFF8A9BB8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subAliases.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${o.designation} • $subAliases',
                    style: const TextStyle(
                      color: Color(0xFF637494),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Star Favorite Button
          GestureDetector(
            onTap: () async {
              try {
                final repo = await AstroObjectRepository.shared();
                await repo.setFavorite(o.id, !saved);
                setState(() => savedOverride = !saved);
                if (field.favorites.contains(o.designation) == saved) {
                  field.toggleFavorite(o.designation);
                }
              } catch (_) {}
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                saved ? Icons.star_rounded : Icons.star_outline_rounded,
                color:
                    saved ? const Color(0xFFFFD54F) : const Color(0xFF8A9BB8),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 1: Catalog Coordinates (with Constellation Diagram)
  // ---------------------------------------------------------------------------
  Widget _buildCoordinatesCard(AstroObject o) {
    return _buildCard(
      icon: Icons.my_location_rounded,
      iconColor: const Color(0xFF7B88FF),
      title: 'Catalog coordinates',
      trailing: const Text(
        'J2000',
        style: TextStyle(
          color: Color(0xFF6B7E9F),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Row(
        children: [
          // Left Coordinates Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _coordRow(
                  'Right Ascension',
                  '${o.raDeg.toStringAsFixed(4)}°  (${(o.raDeg / 15).toStringAsFixed(4)}h)',
                ),
                const SizedBox(height: 8),
                _coordRow('Declination', '${o.decDeg.toStringAsFixed(4)}°'),
              ],
            ),
          ),

          // Right Constellation Star Diagram
          _ConstellationDiagram(constellation: o.constellation ?? 'Sky'),
        ],
      ),
    );
  }

  Widget _coordRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A9BB8), fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card 2: Catalog Properties (2-Column Grid)
  // ---------------------------------------------------------------------------
  Widget _buildPropertiesCard(AstroObject o) {
    return _buildCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF00E5FF),
      title: 'Catalog properties',
      content: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _propItem(
                  'Magnitude',
                  o.magnitude?.toStringAsFixed(2) ?? 'Unavailable',
                ),
              ),
              Expanded(
                child: _propItem(
                  'Type',
                  o.type.name,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _propItem(
                  'Surface brightness',
                  o.surfaceBrightness?.toStringAsFixed(2) ?? 'Unavailable',
                ),
              ),
              Expanded(
                child: _propItem(
                  'Constellation',
                  o.constellation ?? 'Unavailable',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _propItem(
                  'Size',
                  "${o.majorAxisArcmin?.toStringAsFixed(1) ?? '—'}′ × ${o.minorAxisArcmin?.toStringAsFixed(1) ?? '—'}′",
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Source',
                      style:
                          TextStyle(color: Color(0xFF8A9BB8), fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          o.sourceCatalog ?? 'OpenNGC',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: Color(0xFF7B88FF),
                          size: 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Expanded(
                child: _propItem('Data date', '2026-09-30'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _propItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A9BB8), fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card 3: Position Now (with 3D Radar Dial & Prominent Readouts)
  // ---------------------------------------------------------------------------
  Widget _buildPositionNowCard(TargetPlan t) {
    final isAbove = t.now.altitude > 0;

    return _buildCard(
      icon: Icons.track_changes_rounded,
      iconColor: const Color(0xFF00E5FF),
      title: 'Position now',
      content: Row(
        children: [
          // Left Status Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _propItem('Altitude', '${t.now.altitude.toStringAsFixed(1)}°'),
                const SizedBox(height: 8),
                _propItem('Azimuth',
                    '${t.now.azimuth.toStringAsFixed(1)}° ${t.now.direction}'),
                const SizedBox(height: 8),
                const Text(
                  'Status',
                  style: TextStyle(color: Color(0xFF8A9BB8), fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isAbove
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF5252),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAbove ? 'Above horizon' : 'Below horizon',
                      style: TextStyle(
                        color: isAbove
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF5252),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: 3D Radar Compass Dial
          SizedBox(
            width: 82,
            height: 82,
            child: CustomPaint(
              painter: _RadarCompassPainter(
                altitude: t.now.altitude,
                azimuth: t.now.azimuth,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Right: Large Bold Altitude & Azimuth Readouts
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.now.altitude.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Altitude',
                  style: TextStyle(color: Color(0xFF8A9BB8), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.now.azimuth.toStringAsFixed(1)}° ${t.now.direction}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Azimuth',
                  style: TextStyle(color: Color(0xFF8A9BB8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 4: Tonight (Times & Integrated Altitude Graph with Peak Badge)
  // ---------------------------------------------------------------------------
  Widget _buildTonightCard(TargetPlan t) {
    return _buildCard(
      icon: Icons.access_time_rounded,
      iconColor: const Color(0xFF7C4DFF),
      title: 'Tonight',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Times Row
          Row(
            children: [
              Expanded(child: _propItem('Rise', clockTime(t.rise))),
              Expanded(child: _propItem('Transit', clockTime(t.transit))),
              Expanded(child: _propItem('Set', clockTime(t.set))),
            ],
          ),
          const SizedBox(height: 10),
          _propItem(
            'Maximum altitude',
            '${t.peak.position.altitude.toStringAsFixed(1)}° at ${clockTime(t.peak.time)}',
          ),
          const SizedBox(height: 14),

          // Integrated Altitude Chart with Peak Pill Badge
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _PeakAltitudeChartPainter(
                samples: t.samples,
                peakAltitude: t.peak.position.altitude,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 5: Best Imaging Window
  // ---------------------------------------------------------------------------
  Widget _buildBestWindowCard(TargetPlan t, double minimum) {
    final windowText = t.bestWindow == null
        ? 'No interval satisfies the current altitude and darkness limits.'
        : '${clockTime(t.bestWindow!.start)} – ${clockTime(t.bestWindow!.end)}';
    final durText =
        t.bestWindow != null ? '(${durationText(t.bestWindow!.duration)})' : '';

    return _buildCard(
      icon: Icons.star_rounded,
      iconColor: const Color(0xFF7C4DFF),
      title: 'Best imaging window',
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Calendar & Window Times
          Expanded(
            flex: 5,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        windowText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (durText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          durText,
                          style: const TextStyle(
                            color: Color(0xFF8A9BB8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right: Glass Parameter Box
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x99131B38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF283864), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.landscape_rounded,
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Altitude ≥ ${minimum.round()}° and Sun ≤ −18°.\nSampled every 10 min.',
                      style: const TextStyle(
                        color: Color(0xFF8A9BB8),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 6: Moon (with 3D Moon and Separation Dial)
  // ---------------------------------------------------------------------------
  Widget _buildMoonCard(NightReport r, TargetPlan t) {
    final statusText = r.moon.altitude < 0
        ? 'Moon below horizon'
        : t.moonSeparation < 30
            ? 'High lunar interference'
            : t.moonSeparation < 60
                ? 'Moderate lunar interference'
                : 'Low lunar interference';

    final statusColor = r.moon.altitude < 0
        ? const Color(0xFF90A4AE)
        : t.moonSeparation < 30
            ? const Color(0xFFFFB74D)
            : const Color(0xFF00E676);

    return _buildCard(
      icon: Icons.nightlight_round,
      iconColor: const Color(0xFF7C4DFF),
      title: 'Moon',
      content: Row(
        children: [
          // Left: Metrics & Status
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _propItem(
                  'Illumination',
                  '${(r.moonIllumination * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 6),
                _propItem(
                  'Moon altitude',
                  '${r.moon.altitude.toStringAsFixed(1)}°',
                ),
                const SizedBox(height: 6),
                _propItem(
                  'Separation',
                  '${t.moonSeparation.toStringAsFixed(1)}°',
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: 3D Moon Thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC8D6F2).withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/moon_3d.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.nightlight_round,
                  color: Color(0xFFC5CAE9),
                  size: 36,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Right: Moon Separation Orbit Dial
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _MoonSeparationDialPainter(
                separation: t.moonSeparation,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 7: Equipment Fit
  // ---------------------------------------------------------------------------
  Widget _buildEquipmentFitCard(AstroObject o) {
    return _buildCard(
      icon: Icons.camera_alt_outlined,
      iconColor: const Color(0xFF00E5FF),
      title: 'Equipment fit',
      trailing: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.equipment),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x99131B38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF283864), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                'Select equipment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      content: Text(
        _fit(o, field.selectedEquipment),
        style: const TextStyle(
          color: Color(0xFF8A9BB8),
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar(AstroObject o) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xF0070B18),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E2A4A), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Show on sky button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                field.selectedSkyObject.value = o;
                field.selectedSkyTargetId.value = o.designation;
                Get.toNamed(AppRoutes.skyChart, arguments: o.id);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF384A78), width: 1.2),
                backgroundColor: const Color(0xFF0F1730),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.public, color: Color(0xFF7C4DFF), size: 18),
              label: const Text(
                'Show on sky',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Add to plan button
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                field.togglePlan(o.designation);
                setState(() {});
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5D51D6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: Icon(
                field.planned.contains(o.designation)
                    ? Icons.playlist_remove_rounded
                    : Icons.playlist_add_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                field.planned.contains(o.designation)
                    ? 'Remove plan'
                    : 'Add to plan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: Card Container Template
  // ---------------------------------------------------------------------------
  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xDD0D152E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF26355C), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  static String _fit(AstroObject o, Equipment? e) {
    if (e == null) {
      return 'Select an equipment profile to calculate field of view.';
    }
    final x = e.horizontalFov,
        y = e.verticalFov,
        a = o.majorAxisArcmin,
        b = o.minorAxisArcmin;
    if (a == null || b == null) {
      return '${e.name}: ${x.toStringAsFixed(2)}° × ${y.toStringAsFixed(2)}°\nObject dimensions unavailable.';
    }
    final major = a / 60, minor = b / 60;
    final fits = (major <= x && minor <= y) || (major <= y && minor <= x);
    final status = fits
        ? (major < x * .1 && minor < y * .1
            ? 'Very small in frame'
            : 'Fits in frame')
        : 'Too large; mosaic recommended';
    return '${e.name}\nObject ${major.toStringAsFixed(2)}° × ${minor.toStringAsFixed(2)}°\nSensor FOV ${x.toStringAsFixed(2)}° × ${y.toStringAsFixed(2)}°\n$status';
  }
}

// ---------------------------------------------------------------------------
// Custom Painters: Constellation, Radar, Peak Altitude Chart, Moon Separation
// ---------------------------------------------------------------------------

class _ConstellationDiagram extends StatelessWidget {
  const _ConstellationDiagram({required this.constellation});
  final String constellation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 60,
      child: CustomPaint(
        painter: _ConstellationPainter(constellation: constellation),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({required this.constellation});
  final String constellation;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(size.width * 0.15, size.height * 0.35);
    final p2 = Offset(size.width * 0.45, size.height * 0.65);
    final p3 = Offset(size.width * 0.68, size.height * 0.75);
    final p4 = Offset(size.width * 0.88, size.height * 0.78);

    final linePaint = Paint()
      ..color = const Color(0xFF7B88FF).withValues(alpha: 0.65)
      ..strokeWidth = 1.3;

    canvas.drawLine(p1, p2, linePaint);
    canvas.drawLine(p2, p3, linePaint);
    canvas.drawLine(p3, p4, linePaint);

    final starPaint = Paint()..color = const Color(0xFFB388FF);
    for (final p in [p1, p2, p3, p4]) {
      canvas.drawCircle(p, 2.8, starPaint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: constellation,
        style: const TextStyle(
          color: Color(0xFF7B88FF),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.42, size.height * 0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarCompassPainter extends CustomPainter {
  const _RadarCompassPainter({required this.altitude, required this.azimuth});
  final double altitude;
  final double azimuth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF091024),
    );

    // Horizon wave gradient
    final wave = Path()
      ..moveTo(center.dx - radius, center.dy + 4)
      ..quadraticBezierTo(
        center.dx,
        center.dy - 12,
        center.dx + radius,
        center.dy + 4,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0.05,
        math.pi - 0.1,
        false,
      )
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = const Color(0xFF1E3260).withValues(alpha: 0.6),
    );

    // Border ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF384A78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Cardinal ticks & N, S, W, E
    _drawChar(canvas, 'N', Offset(center.dx - 3, 2), const Color(0xFF00E5FF));
    _drawChar(canvas, 'S', Offset(center.dx - 3, size.height - 11),
        const Color(0xFF7E8FA8));
    _drawChar(canvas, 'W', Offset(2, center.dy - 5), const Color(0xFF7E8FA8));
    _drawChar(canvas, 'E', Offset(size.width - 9, center.dy - 5),
        const Color(0xFF7E8FA8));

    // Target position marker
    final azRad = (azimuth - 90) * math.pi / 180;
    final altFrac = (90 - altitude.clamp(-90, 90)) / 180;
    final dist = radius * 0.75 * altFrac;
    final targetPos = Offset(
      center.dx + dist * math.cos(azRad),
      center.dy + dist * math.sin(azRad),
    );

    // Glow dot
    canvas.drawCircle(
      targetPos,
      4,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      targetPos,
      2,
      Paint()..color = Colors.white,
    );
  }

  void _drawChar(Canvas canvas, String char, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PeakAltitudeChartPainter extends CustomPainter {
  const _PeakAltitudeChartPainter({
    required this.samples,
    required this.peakAltitude,
  });
  final List<SkySample> samples;
  final double peakAltitude;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final plot = Rect.fromLTRB(30, 24, size.width - 10, size.height - 24);
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2B4C)
      ..strokeWidth = 0.8;

    void label(String text, Offset pt) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 9, color: Color(0xFF6B7E9F)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, pt);
    }

    // Grid horizontal lines: 90°, 45°, 0°, -45°, -90°
    for (int i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      label('${90 - 45 * i}°', Offset(0, y - 5));
    }

    // Curve Path
    final path = Path();
    Offset? peakOffset;
    double maxAlt = -999;

    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      final x = plot.left + plot.width * i / (samples.length - 1);
      final y = plot.top + plot.height * (90 - s.position.altitude) / 180;
      final pt = Offset(x, y);

      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }

      if (s.position.altitude > maxAlt) {
        maxAlt = s.position.altitude;
        peakOffset = pt;
      }
    }

    // Draw Curve
    final curvePaint = Paint()
      ..color = const Color(0xFF5D51D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, curvePaint);

    // Peak Marker and Guideline
    if (peakOffset != null) {
      // Dashed vertical line to axis
      final dashPaint = Paint()
        ..color = const Color(0xFF5D51D6).withValues(alpha: 0.6)
        ..strokeWidth = 1.0;
      double curY = peakOffset.dy;
      while (curY < plot.bottom) {
        canvas.drawLine(
          Offset(peakOffset.dx, curY),
          Offset(peakOffset.dx, math.min(curY + 4, plot.bottom)),
          dashPaint,
        );
        curY += 7;
      }

      // Peak Bubble Badge
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(peakOffset.dx, peakOffset.dy - 12),
          width: 38,
          height: 18,
        ),
        const Radius.circular(9),
      );
      canvas.drawRRect(
        bubbleRect,
        Paint()..color = const Color(0xFF5D51D6),
      );

      final peakText = TextPainter(
        text: TextSpan(
          text: '${peakAltitude.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      peakText.paint(
        canvas,
        Offset(peakOffset.dx - peakText.width / 2, peakOffset.dy - 17),
      );

      // Dot on peak
      canvas.drawCircle(peakOffset, 3.5, Paint()..color = Colors.white);
    }

    // Time Labels along bottom
    final timeStep = plot.width / 4;
    label('12:32 PM', Offset(plot.left, plot.bottom + 6));
    label('6:32 PM', Offset(plot.left + timeStep - 15, plot.bottom + 6));
    label('12:32 AM', Offset(plot.left + timeStep * 2 - 15, plot.bottom + 6));
    label('6:32 AM', Offset(plot.left + timeStep * 3 - 15, plot.bottom + 6));
    label('12:32 PM', Offset(plot.right - 25, plot.bottom + 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MoonSeparationDialPainter extends CustomPainter {
  const _MoonSeparationDialPainter({required this.separation});
  final double separation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 24.0;

    // Dotted orbit ring
    final orbitPaint = Paint()
      ..color = const Color(0xFF384A78).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, orbitPaint);

    // Connecting separation arc
    final arcPaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.7,
      math.pi * 0.8,
      false,
      arcPaint,
    );

    // Moon marker
    final moonPos = Offset(
      center.dx + radius * math.cos(-math.pi * 0.7),
      center.dy + radius * math.sin(-math.pi * 0.7),
    );
    canvas.drawCircle(moonPos, 4, Paint()..color = const Color(0xFFE0E0E0));

    // Target marker
    final targetPos = Offset(
      center.dx + radius * math.cos(math.pi * 0.1),
      center.dy + radius * math.sin(math.pi * 0.1),
    );
    canvas.drawCircle(targetPos, 3, Paint()..color = const Color(0xFF00E5FF));

    // Separation text in center
    final tp = TextPainter(
      text: TextSpan(
        text: '${separation.toStringAsFixed(1)}°',
        style: const TextStyle(
          color: Color(0xFF8A9BB8),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
