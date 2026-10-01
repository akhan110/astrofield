import 'dart:math' as math;
import 'package:astrofield_ui/services/astronomy_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/app_routes.dart';
import '../controllers/field_controller.dart';
import '../data/catalog.dart';
import '../domain/field_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/astro_drawer.dart';
import '../widgets/object_thumbnail.dart';
import '../widgets/page_header.dart';
import '../widgets/score_ring.dart';

enum FieldPage {
  home,
  sky,
  tonight,
  saved,
  search,
  detail,
  moon,
  sun,
  weather,
  trip,
  sync,
  equipment,
  settings,
  about
}

class FieldScreen extends StatelessWidget {
  const FieldScreen(this.page, {super.key, this.embedded = false});
  final FieldPage page;
  final bool embedded;
  FieldController get c => Get.find<FieldController>();

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(child: Obx(() {
      final report = c.report.value;
      final title = switch (page) {
        FieldPage.home => 'AstroField',
        FieldPage.sky => 'Your sky',
        FieldPage.tonight => 'Tonight planner',
        FieldPage.saved => 'Saved targets',
        FieldPage.search => 'Object catalog',
        FieldPage.detail => 'Object details',
        FieldPage.moon => 'Moon conditions',
        FieldPage.sun => 'Sun & twilight',
        FieldPage.weather => 'Cached weather',
        FieldPage.trip => 'Offline readiness',
        FieldPage.sync => 'Sync center',
        FieldPage.equipment => 'Equipment',
        FieldPage.settings => 'Settings',
        FieldPage.about => 'About & data',
      };
      return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
        PageHeader(
            title: title,
            showBack: !embedded,
            showMenu: embedded,
            subtitle: c.site.value?.name ?? 'Set your observing location',
            trailing: IconButton(
                tooltip: 'Location',
                icon: const Icon(Icons.location_on_outlined),
                onPressed: () => Get.toNamed(AppRoutes.location))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (c.message.value.isNotEmpty)
                    AppCard(
                        child: Row(children: [
                      Expanded(child: Text(c.message.value)),
                      IconButton(
                          tooltip: 'Dismiss message',
                          onPressed: () => c.message.value = '',
                          icon: const Icon(Icons.close))
                    ])),
                  if (c.busy.value)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator()),
                  if (page != FieldPage.about &&
                      page != FieldPage.equipment &&
                      page != FieldPage.settings) ...[
                    Wrap(spacing: 8, children: [
                      TextButton.icon(
                          onPressed: () => _chooseTime(context),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label:
                              Text('${clockTime(c.time.value)} · device time')),
                      TextButton(
                          onPressed: () {
                            c.live.value = true;
                            c.time.value = DateTime.now().toUtc();
                            c.refresh();
                          },
                          child: Text(
                              c.live.value ? 'Live clock' : 'Return to now')),
                    ]),
                    if (c.site.value == null)
                      AppCard(
                          child: Column(children: [
                        const Text('Choose a location to calculate your sky.'),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: () => Get.toNamed(AppRoutes.location),
                            child: const Text('Set location'))
                      ]))
                    else if (report == null && !c.busy.value)
                      OutlinedButton(
                          onPressed: c.refresh,
                          child: const Text('Retry calculation')),
                  ],
                  ..._content(context, report),
                ])),
      ]);
    }));

    if (embedded) return body;
    return Scaffold(
      drawer: const AstroDrawer(),
      body: body,
    );
  }

  Future<void> _chooseTime(BuildContext context) async {
    final current = c.time.value.toLocal();
    final date = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100, 12, 31));
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (time == null) return;
    c.live.value = false;
    c.time.value =
        DateTime(date.year, date.month, date.day, time.hour, time.minute)
            .toUtc();
    await c.refresh();
  }

  List<Widget> _content(BuildContext context, NightReport? r) {
    if (page == FieldPage.about) {
      return [
        _note('Offline astronomy',
            'Positions, Sun/Moon, twilight, catalog search and planning run on this device. Calculations use GeoEngine’s Dart port of Astronomy Engine. The bundled starter catalog contains ${fieldCatalog.length} targets.'),
        _note('Accuracy & interpretation',
            'Altitudes are geometric; rise/set includes standard refraction. Night windows use 10-minute samples and may omit short intervals. No terrain obstruction, extinction, tracking or seeing model is applied. Times use the device timezone, including when planning for a remote site.'),
        _note('Imaging score',
            'A heuristic from altitude, darkness and Moon interference. Deep-sky targets require Sun ≤ −18°; planets require Sun ≤ −6°. Weather and equipment fit are shown separately. A high score is not a guarantee of image quality.'),
        _note('Data credits',
            'OpenNGC catalog centers (CC BY-SA 4.0): github.com/mattiaverga/OpenNGC. GeoEngine / Astronomy Engine: pub.dev/packages/geoengine. Weather: Open-Meteo, CC BY 4.0, free API for non-commercial use. Source issue time is not supplied by the forecast endpoint.'),
        _note('Privacy',
            'Observing location, favorites, equipment and forecast cache stay on this device. Weather sync sends coordinates to Open-Meteo only when you request it. No account is required.'),
        OutlinedButton(
            onPressed: () => showLicensePage(
                context: context, applicationName: 'AstroField'),
            child: const Text('Open-source licenses')),
      ];
    }
    if (page == FieldPage.settings) {
      return [
        _note('Minimum imaging altitude',
            '${c.minimumAltitude.value.round()}° above the mathematical horizon. Trees and mountains are not included.'),
        Slider(
            value: c.minimumAltitude.value,
            min: 5,
            max: 80,
            divisions: 15,
            label: '${c.minimumAltitude.value.round()}°',
            onChanged: (v) => c.minimumAltitude.value = v,
            onChangeEnd: (_) {
              c.persist();
              c.refresh();
            }),
        SwitchListTile(
            title: const Text('Red night mode'),
            subtitle: const Text('Dim red display for use in the field'),
            value: c.redMode.value,
            onChanged: (v) {
              c.redMode.value = v;
              c.persist();
            }),
        _note('Time & units',
            'Times are shown in your device timezone. Angles use degrees; equipment uses millimetres and micrometres. Astronomy does not require a network connection.'),
      ];
    }
    if (page == FieldPage.equipment) {
      return [
        FilledButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.equipmentForm),
            icon: const Icon(Icons.add),
            label: const Text('Add equipment')),
        if (c.equipment.isEmpty)
          _note('No equipment yet',
              'Add sensor size, effective focal length and pixel size to calculate field of view and image scale.'),
        ...c.equipment.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(e.value.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                      'FOV ${e.value.horizontalFov.toStringAsFixed(2)}° × ${e.value.verticalFov.toStringAsFixed(2)}° • ${e.value.imageScale.toStringAsFixed(2)} arcsec/pixel'),
                  Wrap(children: [
                    TextButton(
                        onPressed: () {
                          c.activeEquipment.value = e.key;
                          c.persist();
                        },
                        child: Text(c.activeEquipment.value == e.key
                            ? 'Selected'
                            : 'Use setup')),
                    TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.equipmentForm,
                            arguments: e.key),
                        child: const Text('Edit')),
                    TextButton(
                        onPressed: () async {
                          final remove = await Get.dialog<bool>(AlertDialog(
                              title: const Text('Remove equipment?'),
                              content: Text(e.value.name),
                              actions: [
                                TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: const Text('Remove'))
                              ]));
                          if (remove == true) {
                            c.equipment.removeAt(e.key);
                            c.activeEquipment.value = 0;
                            c.persist();
                          }
                        },
                        child: const Text('Remove'))
                  ]),
                ])))),
      ];
    }
    if (page == FieldPage.weather ||
        page == FieldPage.sync ||
        page == FieldPage.trip) {
      final cache = c.weather.value;
      final matching =
          cache != null && c.site.value != null && cache.matches(c.site.value!);
      final hours = matching
          ? cache.hours
              .where((h) =>
                  !h.time.isBefore(
                      c.time.value.subtract(const Duration(hours: 1))) &&
                  h.time.isBefore(c.time.value.add(const Duration(hours: 24))))
              .toList()
          : [];
      return [
        if (page != FieldPage.weather)
          _note('Offline checks',
              'Location: ${c.site.value == null ? 'missing' : 'saved'}\nCatalog: ${fieldCatalog.length} bundled targets\nAstronomy: ${r == null ? 'not ready' : 'ready'}\nEquipment: ${c.selectedEquipment?.name ?? 'not selected'}\nWeather: ${matching && hours.isNotEmpty ? (cache.stale ? 'cached, stale' : 'cached') : 'unavailable for this site/date'}'),
        _note(
            'Weather cache',
            matching
                ? 'Open-Meteo • downloaded ${clockTime(cache.downloaded)}\n${cache.stale ? 'Stale: more than 6 hours old' : 'Cached forecast, not a live observation'}\nForecast valid times are shown below. Source issue time unavailable.'
                : 'No forecast cached for this observing location. Sync requires internet; astronomy remains available offline.'),
        FilledButton.icon(
            onPressed:
                c.syncing.value || c.site.value == null ? null : c.syncWeather,
            icon: const Icon(Icons.sync),
            label: Text(c.syncing.value ? 'Downloading…' : 'Download weather')),
        if (page == FieldPage.trip)
          _note('Before travel',
              'Set your destination, choose your observing date, save targets and sync weather. Reopen the app in airplane mode to verify your device. One observing site and its latest forecast are stored.'),
        if (page == FieldPage.weather && hours.isEmpty)
          _note('No matching forecast hours',
              'The selected date may be outside the cached forecast. Choose a date within the forecast or download an update.'),
        if (page == FieldPage.weather)
          ...hours.map((h) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(clockTime(h.time)),
              subtitle: Text(
                  'Cloud ${h.cloud?.round() ?? "—"}% • Humidity ${h.humidity?.round() ?? "—"}%\nWind ${h.wind ?? "—"} km/h • Rain chance ${h.precipitation?.round() ?? "—"}%'),
              trailing: Text('${h.temperature ?? "—"} °C'))),
      ];
    }
    if (r == null) return [];
    if (page == FieldPage.moon) {
      return [
        _note('Moon now',
            '${(r.moonIllumination * 100).toStringAsFixed(1)}% illuminated • ${_phase(r.moonPhase)}\nAltitude ${r.moon.altitude.toStringAsFixed(1)}° • Azimuth ${r.moon.azimuth.toStringAsFixed(1)}° ${r.moon.direction}'),
        ...r.events.entries
            .where((e) => e.key.startsWith('Moon'))
            .map((e) => _note(e.key, clockTime(e.value))),
        _note('Target interference',
            'Open a target to see its angular separation from the Moon. A bright Moon above the horizon lowers deep-sky imaging scores.'),
      ];
    }
    if (page == FieldPage.sun) {
      return [
        _note('Sun now',
            'Altitude ${r.sun.altitude.toStringAsFixed(1)}° • ${_darkness(r.sun.altitude)}'),
        _note('Astronomical darkness', _darkWindows(r)),
        ...r.events.entries
            .where((e) => !e.key.startsWith('Moon'))
            .map((e) => _note(e.key, clockTime(e.value))),
        _note('Event period',
            '${clockTime(r.start)} – ${clockTime(r.end)}\nAt high latitudes, some events do not occur. No event does not mean a calculation error.'),
      ];
    }
    if (page == FieldPage.detail) {
      final id = Get.arguments is String
          ? Get.arguments as String
          : fieldCatalog.first.id;
      final matches = r.targets.where((t) => t.object.id == id);
      if (matches.isEmpty) {
        return [
          _note('Target unavailable',
              'This object is not in the bundled catalog.')
        ];
      }
      final t = matches.first;
      final eq = c.selectedEquipment;
      return [
        AppCard(
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ObjectThumbnail(
              id: t.object.id,
              name: t.object.name,
              size: 72,
              borderRadius: 14,
              accentColor: _targetColor(t),
              fallbackIcon: t.object.isPlanet
                  ? Icons.circle_outlined
                  : Icons.auto_awesome,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.object.id} · ${t.object.name}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                      '${t.object.type} • ${t.now.altitude > 0 ? 'Above horizon' : 'Below horizon'}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    TextButton.icon(
                        onPressed: () => c.toggleFavorite(id),
                        icon: Icon(c.favorites.contains(id)
                            ? Icons.bookmark
                            : Icons.bookmark_outline),
                        label: Text(c.favorites.contains(id)
                            ? 'Unsave'
                            : 'Save target')),
                    TextButton.icon(
                        onPressed: () => c.togglePlan(id),
                        icon: const Icon(Icons.playlist_add),
                        label: Text(c.planned.contains(id)
                            ? 'Remove'
                            : 'Add to plan')),
                  ]),
                ],
              ),
            ),
          ],
        )),
        _note('Position now',
            'Altitude ${t.now.altitude.toStringAsFixed(1)}°\nAzimuth ${t.now.azimuth.toStringAsFixed(1)}° ${t.now.direction}\nRA ${t.now.ra.toStringAsFixed(4)}h • Dec ${t.now.dec.toStringAsFixed(4)}° (of date)'),
        _note('Astronomy score',
            '${t.score}/100 now • ${t.nightScore}/100 peak this night\nMoon separation ${t.moonSeparation.toStringAsFixed(1)}° • Weather not included'),
        _note('Rise / transit / set',
            'Rise: ${clockTime(t.rise)}\nTransit: ${clockTime(t.transit)}\nSet: ${clockTime(t.set)}\nPeriod: ${clockTime(r.start)} – ${clockTime(r.end)}'),
        _note('Altitude through the night',
            '0° is the horizon; 90° is overhead. Negative altitude is below the horizon. Peak sampled altitude ${t.peak.position.altitude.toStringAsFixed(1)}° at ${clockTime(t.peak.time)}.'),
        AppCard(child: RealAltitudeChart(samples: t.samples)),
        _note(
            'Imaging windows',
            t.windows.isEmpty
                ? 'No interval meets your altitude and darkness thresholds.'
                : t.windows
                    .map((w) =>
                        '${clockTime(w.start)} – ${clockTime(w.end)} (${durationText(w.duration)})')
                    .join('\n')),
        _note('Window criteria',
            'Altitude ≥ ${c.minimumAltitude.value.round()}° and Sun ≤ ${t.object.isPlanet ? '-6' : '-18'}°. Conservative 10-minute samples; Moon interference affects score, not the window boundaries.'),
        _note(
            'Equipment framing',
            eq == null
                ? 'Select equipment to calculate framing.'
                : '${eq.name}: ${eq.horizontalFov.toStringAsFixed(2)}° × ${eq.verticalFov.toStringAsFixed(2)}°\n${t.object.sizeArcmin > 0 ? 'Catalog major axis ${t.object.sizeArcmin.toStringAsFixed(1)} arcmin. ${t.object.sizeArcmin / 60 <= math.min(eq.horizontalFov, eq.verticalFov) ? 'Fits within either sensor axis.' : t.object.sizeArcmin / 60 <= math.max(eq.horizontalFov, eq.verticalFov) ? 'May fit with rotation; check target shape.' : 'Exceeds the long sensor axis; consider a mosaic.'}' : 'Target angular size not available.'}'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => Get.toNamed(
                AppRoutes.framingSimulator,
                arguments: t.object.id,
              ),
              icon: const Icon(Icons.crop_free_rounded),
              label: const Text('Simulate sensor framing'),
            ),
            OutlinedButton(
              onPressed: () => Get.toNamed(AppRoutes.skyChart),
              child: const Text('Open sky chart'),
            ),
          ],
        ),
      ];
    }
    if (page == FieldPage.sky) {
      final allVisible = r.targets.where((t) => t.now.altitude > 0).toList();
      final filteredTargets =
          allVisible.where((t) => c.matchesSkyFilter(t)).toList();

      final filterList = [
        ('All', allVisible.length),
        (
          'Messier',
          allVisible
              .where((t) => RegExp(r'^M\d+$').hasMatch(t.object.id))
              .length
        ),
        (
          'Nebulae',
          allVisible
              .where((t) => t.object.type.toLowerCase().contains('nebula'))
              .length
        ),
        (
          'Galaxies',
          allVisible
              .where((t) => t.object.type.toLowerCase().contains('galaxy'))
              .length
        ),
        (
          'Clusters',
          allVisible
              .where((t) => t.object.type.toLowerCase().contains('cluster'))
              .length
        ),
        ('Planets', allVisible.where((t) => t.object.type == 'Planet').length),
        ('Stars', allVisible.where((t) => t.object.type == 'Star').length),
        ('High (>30°)', allVisible.where((t) => t.now.altitude >= 30.0).length),
        (
          'Saved',
          allVisible.where((t) => c.favorites.contains(t.object.id)).length
        ),
      ];

      final selectedTarget = c.selectedSkyTargetId.value != null
          ? r.targets
              .where((t) => t.object.id == c.selectedSkyTargetId.value)
              .firstOrNull
          : null;

      return [
        _note('Horizon Star Chart',
            'North up • East right • Center = Zenith (90°) • Outer edge = Horizon (0°).\nShowing calculated sky for ${clockTime(r.time)} at ${c.site.value?.name ?? "Observing Site"}.'),
        if (c.selectedSkyObject.value != null && c.site.value != null)
          _note('Selected catalog object',
              '${c.selectedSkyObject.value!.designation} • ${c.selectedSkyObject.value!.displayName}\nThe chart pans to its calculated altitude and azimuth. Objects below the horizon cannot be centered in the visible hemisphere.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: filterList.map((f) {
              final isSelected = c.skyFilter.value == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('${f.$1} (${f.$2})'),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  backgroundColor: AppColors.surface2,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      c.skyFilter.value = f.$1;
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              Text(
                '${filteredTargets.length} ${c.skyFilter.value.toLowerCase()} on chart',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ChoiceChip(
                label: const Text('Labels'),
                avatar: Icon(
                  c.skyShowLabels.value
                      ? Icons.label_rounded
                      : Icons.label_off_rounded,
                  size: 14,
                  color: c.skyShowLabels.value
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
                selected: c.skyShowLabels.value,
                selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                backgroundColor: AppColors.surface2,
                side: BorderSide(
                  color: c.skyShowLabels.value
                      ? AppColors.secondary
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: c.skyShowLabels.value
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (val) => c.skyShowLabels.value = val,
              ),
            ],
          ),
        ),
        AppCard(
          child: SizedBox(
            height: 380,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: LayoutBuilder(
                builder: (context, box) => _sky(box, r, filteredTargets),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem('Nebula', AppColors.secondary),
              _legendItem('Galaxy', AppColors.violet),
              _legendItem('Cluster', AppColors.primary),
              _legendItem('Planet', AppColors.amber),
              _legendItem('Star', Colors.white),
            ],
          ),
        ),
        if (selectedTarget != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selectedTarget.object.isPlanet
                            ? Icons.circle_outlined
                            : Icons.auto_awesome,
                        color: _targetColor(selectedTarget),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedTarget.object.id} · ${selectedTarget.object.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => c.selectedSkyTargetId.value = null,
                        tooltip: 'Deselect',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedTarget.object.type} in ${selectedTarget.object.constellation} • Alt: ${selectedTarget.now.altitude.toStringAsFixed(1)}° ${selectedTarget.now.direction} • Score: ${selectedTarget.score}/100',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => Get.toNamed(
                          AppRoutes.objectDetail,
                          arguments: selectedTarget.object.id,
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('View Target Details'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            c.toggleFavorite(selectedTarget.object.id),
                        icon: Icon(
                          c.favorites.contains(selectedTarget.object.id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 16,
                        ),
                        label: Text(
                          c.favorites.contains(selectedTarget.object.id)
                              ? 'Saved'
                              : 'Save',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            'Visible ${c.skyFilter.value} Objects (${filteredTargets.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (filteredTargets.isEmpty)
          _note(
            'No ${c.skyFilter.value} visible',
            'There are currently no objects of this category above the horizon at this time. Try selecting "All" or choosing another observing time.',
          )
        else
          ...filteredTargets.map((t) => _tile(t)),
      ];
    }
    final tonight = page == FieldPage.tonight;
    final saved = page == FieldPage.saved;
    final search = page == FieldPage.search;
    var targets = c.targets(tonight: tonight, saved: saved, search: search);
    if (page == FieldPage.home) {
      targets = targets.where((t) => t.score > 0).take(8).toList();
    }
    if (tonight) targets = targets.where((t) => t.bestWindow != null).toList();
    return [
      if (page == FieldPage.home) ...[
        _note('Current sky',
            '${_darkness(r.sun.altitude)} • Moon ${(r.moonIllumination * 100).round()}% illuminated\n${clockTime(r.time)} · device timezone'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.search),
              icon: const Icon(Icons.search),
              label: const Text('Catalog')),
          OutlinedButton(
              onPressed: () => Get.toNamed(AppRoutes.weather),
              child: const Text('Weather')),
          OutlinedButton(
              onPressed: () => Get.toNamed(AppRoutes.equipment),
              child: const Text('Equipment'))
        ]),
        _note('Best targets now',
            'Ranked by altitude, darkness and Moon interference. Minimum altitude ${c.minimumAltitude.value.round()}°.'),
      ],
      if (tonight) ...[
        _note('Astronomical darkness', _darkWindows(r)),
        if (c.planned.isNotEmpty)
          _note(
              'Your plan',
              r.targets
                  .where((t) => c.planned.contains(t.object.id))
                  .map((t) =>
                      '${t.object.id}: ${t.bestWindow == null ? 'No suitable window' : clockTime(t.bestWindow!.start)}')
                  .join('\n')),
        _note('Best targets this night',
            'Ranked by peak astronomy score. Windows use ${c.minimumAltitude.value.round()}° minimum altitude; times use your device timezone.'),
      ],
      if (search)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextField(
                onChanged: (q) => c.query.value = q,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Catalog, name or type'))),
      if (targets.isEmpty)
        _note(
            saved ? 'No saved targets' : 'No matching targets',
            saved
                ? 'Bookmark an object from the catalog to revisit it here.'
                : 'Try the catalog, another time, or a different altitude threshold.'),
      ...targets.map((t) => _tile(t, tonight: tonight)),
    ];
  }

  Widget _tile(TargetPlan t, {bool tonight = false}) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
          onTap: () =>
              Get.toNamed(AppRoutes.objectDetail, arguments: t.object.id),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ObjectThumbnail(
              id: t.object.id,
              name: t.object.name,
              size: 44,
              borderRadius: 12,
              accentColor: _targetColor(t),
              fallbackIcon: t.object.isPlanet
                  ? Icons.circle_outlined
                  : Icons.auto_awesome,
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${t.object.id} · ${t.object.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                      tonight
                          ? (t.bestWindow == null
                              ? 'No window'
                              : '${clockTime(t.bestWindow!.start)} – ${clockTime(t.bestWindow!.end)}')
                          : '${t.now.altitude.toStringAsFixed(1)}° ${t.now.direction} • ${t.object.type}',
                      style: const TextStyle(fontSize: 12))
                ])),
            IconButton(
                tooltip: c.favorites.contains(t.object.id)
                    ? 'Remove from saved'
                    : 'Save target',
                onPressed: () => c.toggleFavorite(t.object.id),
                icon: Icon(c.favorites.contains(t.object.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border)),
            ScoreRing(score: tonight ? t.nightScore : t.score, size: 44),
          ])));

  static Color _targetColor(TargetPlan t) {
    if (t.object.isPlanet) return AppColors.amber;
    final type = t.object.type.toLowerCase();
    if (type.contains('nebula')) return AppColors.secondary;
    if (type.contains('galaxy')) return AppColors.violet;
    if (type.contains('cluster')) return AppColors.primary;
    if (t.object.type == 'Star') return const Color(0xFFFFFFFF);
    return AppColors.primary;
  }

  static Widget _legendItem(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );

  Widget _sky(
      BoxConstraints box, NightReport r, List<TargetPlan> visibleTargets) {
    final size = math.min(box.maxWidth, box.maxHeight);
    final radius = size / 2 - 24;
    final center = Offset(box.maxWidth / 2, box.maxHeight / 2);

    final object = c.selectedSkyObject.value, site = c.site.value;
    SkyPosition? selected;
    if (object != null && site != null) {
      try {
        selected =
            LocalAstronomyEngine().positionForObject(object, site, r.time);
      } catch (_) {}
    }
    final distance = selected == null || selected.altitude <= 0
        ? 0.0
        : radius * (1 - selected.altitude / 90);
    final shift = selected == null || selected.altitude <= 0
        ? Offset.zero
        : Offset(-distance * math.sin(selected.azimuth * math.pi / 180),
            distance * math.cos(selected.azimuth * math.pi / 180));
    return ClipRect(
        child: Transform.translate(
            offset: shift,
            child: SizedBox(
                width: box.maxWidth,
                height: box.maxHeight,
                child: Stack(children: [
                  Positioned.fill(
                      child: CustomPaint(painter: HorizonPainter())),
                  if (r.moon.altitude > -5.0) _moonWidget(center, radius, r),
                  for (final t in visibleTargets)
                    _targetWidget(center, radius, t),
                  if (selected != null && selected.altitude > 0)
                    Positioned(
                        left: center.dx +
                            distance *
                                math.sin(selected.azimuth * math.pi / 180) -
                            32,
                        top: center.dy -
                            distance *
                                math.cos(selected.azimuth * math.pi / 180) -
                            24,
                        child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: AppColors.surface2,
                                border: Border.all(
                                    color: AppColors.amber, width: 2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(object!.designation,
                                style: const TextStyle(
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10)))),
                ]))));
  }

  Widget _moonWidget(Offset center, double radius, NightReport r) {
    final mAlt = r.moon.altitude.clamp(0.0, 90.0);
    final mDist = radius * (1.0 - mAlt / 90.0);
    final mAz = r.moon.azimuth * math.pi / 180.0;
    final mx = center.dx + mDist * math.sin(mAz);
    final my = center.dy - mDist * math.cos(mAz);

    return Positioned(
      left: mx - 24,
      top: my - 24,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.toNamed(AppRoutes.moon),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.2),
                  border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.6),
                      width: 1.5),
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  size: 13,
                  color: AppColors.amber,
                ),
              ),
              if (c.skyShowLabels.value)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'Moon ${(r.moonIllumination * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetWidget(Offset center, double radius, TargetPlan t) {
    final isSelected = c.selectedSkyTargetId.value == t.object.id;
    final color = _targetColor(t);
    final dist = radius * (1.0 - (t.now.altitude / 90.0).clamp(0.0, 1.0));
    final azRad = t.now.azimuth * math.pi / 180.0;
    final x = center.dx + dist * math.sin(azRad);
    final y = center.dy - dist * math.cos(azRad);

    final dotSize = isSelected ? 10.0 : (t.object.isPlanet ? 8.0 : 6.0);

    return Positioned(
      left: x - 26,
      top: y - 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          c.selectedSkyTargetId.value = isSelected ? null : t.object.id;
        },
        child: SizedBox(
          width: 52,
          height: 42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: dotSize + (isSelected ? 10 : 0),
                height: dotSize + (isSelected ? 10 : 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? color.withValues(alpha: 0.3)
                      : Colors.transparent,
                  border:
                      isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: isSelected ? 8 : 3,
                        spreadRadius: isSelected ? 2 : 0,
                      )
                    ],
                  ),
                ),
              ),
              if (c.skyShowLabels.value)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.5, vertical: 0.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                  child: Text(
                    t.object.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.secondary : color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _note(String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(body)
      ])));
  static String _darkness(double a) => a <= -18
      ? 'Astronomical darkness'
      : a <= -12
          ? 'Astronomical twilight'
          : a <= -6
              ? 'Nautical twilight'
              : a <= -.833
                  ? 'Civil twilight'
                  : 'Daylight';
  static String _phase(double phase) => const [
        'New Moon',
        'Waxing crescent',
        'First quarter',
        'Waxing gibbous',
        'Full Moon',
        'Waning gibbous',
        'Last quarter',
        'Waning crescent'
      ][((phase + 22.5) / 45).floor() % 8];
  static String _darkWindows(NightReport r) => r.darkness.isEmpty
      ? 'No astronomical darkness in this period.'
      : r.darkness
          .map((w) =>
              '${clockTime(w.start)} – ${clockTime(w.end)}\n${durationText(w.duration)} (10-minute sampling)')
          .join('\n');
}

class RealAltitudeChart extends StatelessWidget {
  const RealAltitudeChart({super.key, required this.samples});
  final List<SkySample> samples;
  @override
  Widget build(BuildContext context) => Semantics(
      label:
          'Target altitude chart, minus 90 to 90 degrees. Time labels use the device timezone.',
      child: SizedBox(
          height: 210,
          child: CustomPaint(
              size: const Size(double.infinity, 210),
              painter: AltitudeSeriesPainter(samples))));
}

class AltitudeSeriesPainter extends CustomPainter {
  AltitudeSeriesPainter(this.samples);
  final List<SkySample> samples;
  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || size.width < 60) return;
    final plot = Rect.fromLTRB(32, 12, size.width - 8, size.height - 30);
    final grid = Paint()..color = AppColors.border;
    void label(String text, Offset point) {
      final p = TextPainter(
          text: TextSpan(
              text: text,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          textDirection: TextDirection.ltr)
        ..layout();
      p.paint(canvas, point);
    }

    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      label('${90 - 45 * i}°', Offset(0, y - 6));
    }
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final p = Offset(plot.left + plot.width * i / (samples.length - 1),
          plot.top + plot.height * (90 - samples[i].position.altitude) / 180);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke);
    for (var i = 0; i <= 4; i++) {
      final t = samples[((samples.length - 1) * i / 4).round()].time.toLocal();
      final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final period = t.hour >= 12 ? 'PM' : 'AM';
      label(
          '$h12:${t.minute.toString().padLeft(2, '0')} $period',
          Offset(
              (plot.left + plot.width * i / 4 - 18).clamp(0, size.width - 40),
              plot.bottom + 10));
    }
  }

  @override
  bool shouldRepaint(covariant AltitudeSeriesPainter old) =>
      old.samples != samples;
}

class HorizonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = math.min(size.width, size.height) / 2 - 24;

    // Background sky disk with radial gradient
    final skyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF10172B),
          Color(0xFF070B16),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, skyPaint);

    final p = Paint()
      ..color = AppColors.border.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dashPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Altitude circles: 0° (horizon), 30°, 60°
    canvas.drawCircle(center, radius, p);
    canvas.drawCircle(center, radius * 2 / 3, dashPaint);
    canvas.drawCircle(center, radius * 1 / 3, dashPaint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), dashPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), dashPaint);

    // Center Zenith cross
    final zenithPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx - 6, center.dy),
        Offset(center.dx + 6, center.dy), zenithPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 6),
        Offset(center.dx, center.dy + 6), zenithPaint);

    // Altitude ring labels
    final altPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final alt in [
      (radius * 2 / 3, '30°'),
      (radius * 1 / 3, '60°'),
      (0.0, 'Z')
    ]) {
      altPainter.text = TextSpan(
        text: alt.$2,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      );
      altPainter.layout();
      altPainter.paint(canvas, Offset(center.dx + 4, center.dy - alt.$1 - 10));
    }

    // Cardinal directions
    for (final entry in {
      'N': Offset(center.dx - 5, center.dy - radius - 20),
      'E': Offset(center.dx + radius + 6, center.dy - 8),
      'S': Offset(center.dx - 5, center.dy + radius + 4),
      'W': Offset(center.dx - radius - 18, center.dy - 8)
    }.entries) {
      final t = TextPainter(
          text: TextSpan(
              text: entry.key,
              style: TextStyle(
                  color: entry.key == 'N'
                      ? AppColors.secondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          textDirection: TextDirection.ltr)
        ..layout();
      t.paint(canvas, entry.value);
    }
  }

  @override
  bool shouldRepaint(covariant HorizonPainter old) => false;
}
