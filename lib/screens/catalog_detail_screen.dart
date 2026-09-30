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
import '../widgets/app_card.dart';
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
  final target = CatalogObject(o.designation, o.displayName, o.type.name,
      ra: o.raDeg / 15,
      dec: o.decDeg,
      sizeArcmin: o.majorAxisArcmin ?? 0,
      magnitude: o.magnitude,
      constellation: o.constellation ?? '');
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
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Obx(() {
        final site = field.site.value,
            time = field.time.value,
            minimum = field.minimumAltitude.value;
        final id = Get.arguments is String ? Get.arguments as String : 'M42';
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
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  TextButton(
                      onPressed: () => setState(() {
                            cacheKey = null;
                          }),
                      child: const Text('Retry'))
                ]));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!,
                  o = data.object,
                  r = data.report,
                  t = r?.targets.single,
                  saved = savedOverride ?? data.saved;
              final image = RegExp(r'^M\d+$').hasMatch(o.designation)
                  ? 'assets/catalog/thumbnails/${o.designation}.jpg'
                  : null;
              return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Row(children: [
                      IconButton.filledTonal(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(o.designation,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      IconButton(
                          tooltip: saved ? 'Remove from saved' : 'Save target',
                          onPressed: () async {
                            try {
                              final repo = await AstroObjectRepository.shared();
                              await repo.setFavorite(o.id, !saved);
                              setState(() => savedOverride = !saved);
                              if (field.favorites.contains(o.designation) ==
                                  saved) {
                                field.toggleFavorite(o.designation);
                              }
                            } catch (_) {
                              Get.snackbar(
                                  'Save failed', 'Could not update favorites.');
                            }
                          },
                          icon: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_border))
                    ]),
                    AppCard(
                        child: Row(children: [
                      if (image != null)
                        ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(image,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: Icon(Icons.auto_awesome)))),
                      if (image != null) const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(o.displayName,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(
                                '${o.type.name} • ${o.constellation ?? 'Constellation unavailable'}'),
                            Text(
                                o.identifiers
                                    .map((e) => e.designation)
                                    .join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11))
                          ]))
                    ])),
                    _card('Catalog coordinates',
                        'J2000 RA ${o.raDeg.toStringAsFixed(4)}° / ${(o.raDeg / 15).toStringAsFixed(4)}h\nJ2000 Dec ${o.decDeg.toStringAsFixed(4)}°'),
                    _card('Catalog properties',
                        'Magnitude ${o.magnitude?.toStringAsFixed(2) ?? 'Unavailable'} • Surface brightness ${o.surfaceBrightness?.toStringAsFixed(2) ?? 'Unavailable'}\nSize ${o.majorAxisArcmin?.toStringAsFixed(1) ?? '—'}′ × ${o.minorAxisArcmin?.toStringAsFixed(1) ?? '—'}′\nSource: ${o.sourceCatalog ?? 'Unknown'} (${o.sourceVersion ?? 'version unknown'})'),
                    if (t == null)
                      _card('Observing site needed',
                          'Set GPS or manual coordinates for live positions and tonight’s windows.')
                    else ...[
                      _card('Position now',
                          'Altitude ${t.now.altitude.toStringAsFixed(1)}° • Azimuth ${t.now.azimuth.toStringAsFixed(1)}° ${t.now.direction}\n${t.now.altitude > 0 ? 'Above' : 'Below'} the mathematical horizon'),
                      _card('Tonight',
                          'Rise: ${clockTime(t.rise)}\nTransit: ${clockTime(t.transit)}\nSet: ${clockTime(t.set)}\nMaximum sampled altitude: ${t.peak.position.altitude.toStringAsFixed(1)}° at ${clockTime(t.peak.time)}'),
                      AppCard(child: RealAltitudeChart(samples: t.samples)),
                      _card(
                          'Best imaging window',
                          t.bestWindow == null
                              ? 'No interval satisfies the current altitude and darkness limits.'
                              : '${clockTime(t.bestWindow!.start)} – ${clockTime(t.bestWindow!.end)} (${durationText(t.bestWindow!.duration)})\nAltitude ≥ ${minimum.round()}° and Sun ≤ −18°. Sampled every 10 minutes.'),
                      _card(
                          'Moon',
                          'Illumination ${(r!.moonIllumination * 100).toStringAsFixed(1)}% • Moon altitude ${r.moon.altitude.toStringAsFixed(1)}°\nSeparation ${t.moonSeparation.toStringAsFixed(1)}°\n${r.moon.altitude < 0 ? 'Moon below horizon' : t.moonSeparation < 30 ? 'High lunar interference' : t.moonSeparation < 60 ? 'Moderate lunar interference' : 'Lower lunar interference'}'),
                    ],
                    _card('Equipment fit', _fit(o, field.selectedEquipment)),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                          onPressed: () {
                            field.selectedSkyObject.value = o;
                            field.selectedSkyTargetId.value = o.designation;
                            Get.toNamed(AppRoutes.skyChart, arguments: o.id);
                          },
                          icon: const Icon(Icons.public),
                          label: const Text('Show on sky')),
                      FilledButton.icon(
                          onPressed: () {
                            field.togglePlan(o.designation);
                            setState(() {});
                          },
                          icon: const Icon(Icons.playlist_add),
                          label: Text(field.planned.contains(o.designation)
                              ? 'Remove from plan'
                              : 'Add to plan'))
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                        'Images are real survey cutouts when available. Other targets use a placeholder.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ]);
            });
      })));
  static Widget _card(String title, String value) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(value)
      ])));
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
