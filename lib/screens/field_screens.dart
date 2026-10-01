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
    const hasCosmicHeader = true;
    final content = Obx(() {
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
            subtitle: c.site.value?.name ??
                (hasCosmicHeader
                    ? 'Remote Dark-Sky Site'
                    : 'Set your observing location'),
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
                    if (hasCosmicHeader)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
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
                                        child: Text(
                                          '${clockTime(c.time.value)} · device time',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFD6D0FA),
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                c.live.value = true;
                                c.time.value = DateTime.now().toUtc();
                                c.refresh();
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
                                      c.live.value
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
                      )
                    else
                      Wrap(spacing: 8, children: [
                        TextButton.icon(
                            onPressed: () => _chooseTime(context),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                                '${clockTime(c.time.value)} · device time')),
                        TextButton(
                            onPressed: () {
                              c.live.value = true;
                              c.time.value = DateTime.now().toUtc();
                              c.refresh();
                            },
                            child: Text(c.live.value
                                ? 'Live clock'
                                : 'Return to now')),
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
    });

    final body = hasCosmicHeader
        ? Stack(
            children: [
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
              SafeArea(child: content),
            ],
          )
        : SafeArea(child: content);

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
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AstroField',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v1.0.0 • Offline Astronomy Field Engine',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8A9BB8),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D51D6), Color(0xFF8E72FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D51D6).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Get.toNamed(AppRoutes.userManual),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Read Field Guide & User Manual',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: OutlinedButton(
            onPressed: () => showLicensePage(
                context: context, applicationName: 'AstroField'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9AA8FF),
              side: const BorderSide(color: Color(0xFF334673)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('View open-source licenses'),
          ),
        ),
      ];
    }
    if (page == FieldPage.settings) {
      return [
        _note('Minimum imaging altitude',
            '${c.minimumAltitude.value.round()}° above the mathematical horizon. Trees and mountains are not included.'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xDD0D152E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF243358), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.terrain_rounded,
                  color: Color(0xFF8E72FF), size: 20),
              const SizedBox(width: 10),
              Text(
                '${c.minimumAltitude.value.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Expanded(
                child: Slider(
                  value: c.minimumAltitude.value,
                  min: 5,
                  max: 80,
                  divisions: 15,
                  activeColor: const Color(0xFF8E72FF),
                  inactiveColor: const Color(0xFF243358),
                  label: '${c.minimumAltitude.value.round()}°',
                  onChanged: (v) => c.minimumAltitude.value = v,
                  onChangeEnd: (_) {
                    c.persist();
                    c.refresh();
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xDD0D152E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF243358), width: 1.2),
          ),
          child: SwitchListTile(
            activeColor: const Color(0xFFFF5252),
            title: const Text(
              'Red night mode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            subtitle: const Text(
              'Dim red display for dark adaptation in the field',
              style: TextStyle(color: Color(0xFF8A9BB8), fontSize: 12.5),
            ),
            value: c.redMode.value,
            onChanged: (v) {
              c.redMode.value = v;
              c.persist();
            },
          ),
        ),
        _note('Time & units',
            'Times are shown in your device timezone. Angles use degrees; equipment uses millimetres and micrometres. Astronomy does not require a network connection.'),
      ];
    }
    if (page == FieldPage.equipment) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D51D6), Color(0xFF8E72FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D51D6).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Get.toNamed(AppRoutes.equipmentForm),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Equipment Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (c.equipment.isEmpty)
          _note('No equipment yet',
              'Add sensor size, effective focal length and pixel size to calculate field of view and image scale.'),
        ...c.equipment.asMap().entries.map((e) {
          final isSelected = c.activeEquipment.value == e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xDD0D152E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6B4EE6)
                      : const Color(0xFF243358),
                  width: isSelected ? 1.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF6B4EE6).withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x3300E676),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF00E676), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF00E676)),
                              SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'FOV ${e.value.horizontalFov.toStringAsFixed(2)}° × ${e.value.verticalFov.toStringAsFixed(2)}° • ${e.value.imageScale.toStringAsFixed(2)} arcsec/px',
                    style: const TextStyle(
                      color: Color(0xFF8A9BB8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              c.activeEquipment.value = e.key;
                              c.persist();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8E72FF),
                              side: const BorderSide(
                                  color: Color(0xFF6B4EE6)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Use Setup'),
                          ),
                        ),
                      OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.equipmentForm,
                            arguments: e.key),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF334673)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove equipment',
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFFF5252), size: 20),
                        onPressed: () async {
                          final remove = await Get.dialog<bool>(AlertDialog(
                              backgroundColor: const Color(0xFF0D152E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(
                                    color: Color(0xFF243358)),
                              ),
                              title: const Text('Remove equipment?',
                                  style: TextStyle(color: Colors.white)),
                              content: Text(e.value.name,
                                  style: const TextStyle(
                                      color: Color(0xFF8A9BB8))),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Get.back(result: false),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            color: Color(0xFF8A9BB8)))),
                                TextButton(
                                    onPressed: () =>
                                        Get.back(result: true),
                                    child: const Text('Remove',
                                        style: TextStyle(
                                            color: Color(0xFFFF5252)))),
                              ]));
                          if (remove == true) {
                            c.equipment.removeAt(e.key);
                            c.activeEquipment.value = 0;
                            c.persist();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D51D6), Color(0xFF8E72FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D51D6).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: c.syncing.value || c.site.value == null
                    ? null
                    : c.syncWeather,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        c.syncing.value
                            ? 'Downloading Weather Forecast…'
                            : 'Download Weather Forecast',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (page == FieldPage.trip)
          _note('Before travel',
              'Set your destination, choose your observing date, save targets and sync weather. Reopen the app in airplane mode to verify your device. One observing site and its latest forecast are stored.'),
        if (page == FieldPage.weather && hours.isEmpty)
          _note('No matching forecast hours',
              'The selected date may be outside the cached forecast. Choose a date within the forecast or download an update.'),
        if (page == FieldPage.weather)
          ...hours.map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xCC0D152E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF233054), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF162040),
                      ),
                      child: Icon(
                        (h.cloud ?? 0) < 25
                            ? Icons.nightlight_round
                            : Icons.cloud_outlined,
                        color: (h.cloud ?? 0) < 25
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF8A9BB8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clockTime(h.time),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cloud ${h.cloud?.round() ?? "—"}% • Humidity ${h.humidity?.round() ?? "—"}% • Wind ${h.wind ?? "—"} km/h',
                            style: const TextStyle(
                              color: Color(0xFF8A9BB8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${h.temperature ?? "—"} °C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ];
    }
    if (r == null) return [];
    if (page == FieldPage.moon) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xDD0D152E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF26355C), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phase(r.moonPhase),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(r.moonIllumination * 100).toStringAsFixed(1)}% illuminated',
                        style: const TextStyle(
                          color: Color(0xFF8A9BB8),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Altitude: ${r.moon.altitude.toStringAsFixed(1)}° (${r.moon.altitude > 0 ? "Above horizon" : "Below horizon"})',
                        style: TextStyle(
                          color: r.moon.altitude > 0
                              ? const Color(0xFF00E676)
                              : const Color(0xFF90A4AE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xDD0D152E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF26355C), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF5722)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _darkness(r.sun.altitude),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sun altitude: ${r.sun.altitude.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          color: Color(0xFF8A9BB8),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        _horizonHeaderCard(context, r),
        if (c.selectedSkyObject.value != null && c.site.value != null)
          _note('Selected catalog object',
              '${c.selectedSkyObject.value!.designation} • ${c.selectedSkyObject.value!.displayName}\nThe chart pans to its calculated altitude and azimuth. Objects below the horizon cannot be centered in the visible hemisphere.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: filterList.map((f) {
              final isSelected = c.skyFilter.value == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => c.skyFilter.value = f.$1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4361EE)
                            : const Color(0xCC0D1427),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5C7CFA)
                              : const Color(0xFF1E2A4A),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4361EE)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_box_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${f.$1} (${f.$2})',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF90A0C5),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xCC0E172F),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFF233258),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.layers_rounded,
                      size: 20, color: Color(0xFF8FA0FF)),
                  tooltip: 'Toggle Star Map Layers',
                  onPressed: () {
                    c.skyShowLabels.value = !c.skyShowLabels.value;
                  },
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => c.skyShowLabels.value = !c.skyShowLabels.value,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0E172F),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: c.skyShowLabels.value
                          ? const Color(0xFF2E6FF2)
                          : const Color(0xFF233258),
                      width: 1.3,
                    ),
                    boxShadow: c.skyShowLabels.value
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2E6FF2)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (c.skyShowLabels.value) ...[
                        const Icon(Icons.check_rounded,
                            size: 16, color: Color(0xFF82B1FF)),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'Labels',
                        style: TextStyle(
                          color: c.skyShowLabels.value
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xCC0E172F),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFF233258),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.tune_rounded,
                      size: 20, color: Color(0xFF8FA0FF)),
                  tooltip: 'Observation Thresholds',
                  onPressed: () => Get.toNamed(AppRoutes.settings),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xCC0E172F),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFF233258),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.crop_free_rounded,
                      size: 20, color: Color(0xFF8FA0FF)),
                  tooltip: 'Fullscreen Sky Chart',
                  onPressed: () => Get.toNamed(AppRoutes.skyChart),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 440,
          decoration: BoxDecoration(
            color: const Color(0xFF04060E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1E2B4E).withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: LayoutBuilder(
                  builder: (context, box) => _sky(box, r, filteredTargets),
                ),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(double.infinity, 32),
                    painter: ForestHorizonSilhouettePainter(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF233055),
              width: 1,
            ),
          ),
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
              child: Row(
                children: [
                  ObjectThumbnail(
                    id: selectedTarget.object.id,
                    name: selectedTarget.object.name,
                    size: 52,
                    borderRadius: 12,
                    accentColor: _targetColor(selectedTarget),
                    fallbackIcon: selectedTarget.object.isPlanet
                        ? Icons.circle_outlined
                        : Icons.auto_awesome,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${selectedTarget.object.id} · ${selectedTarget.object.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () =>
                                  c.selectedSkyTargetId.value = null,
                              tooltip: 'Deselect',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selectedTarget.object.type} in ${selectedTarget.object.constellation} • Alt: ${selectedTarget.now.altitude.toStringAsFixed(1)}° ${selectedTarget.now.direction} • Score: ${selectedTarget.score}/100',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () => Get.toNamed(
                                AppRoutes.objectDetail,
                                arguments: selectedTarget.object.id,
                              ),
                              icon: const Icon(Icons.visibility_rounded,
                                  size: 14),
                              label: const Text('Details',
                                  style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  c.toggleFavorite(selectedTarget.object.id),
                              icon: Icon(
                                c.favorites
                                        .contains(selectedTarget.object.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 14,
                              ),
                              label: Text(
                                c.favorites
                                        .contains(selectedTarget.object.id)
                                    ? 'Saved'
                                    : 'Save',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
        _darknessCard(context, r),
        if (c.planned.isNotEmpty)
          _note(
              'Your plan',
              r.targets
                  .where((t) => c.planned.contains(t.object.id))
                  .map((t) =>
                      '${t.object.id}: ${t.bestWindow == null ? 'No suitable window' : clockTime(t.bestWindow!.start)}')
                  .join('\n')),
        _bestTargetsHeaderCard(context),
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

  Widget _darknessCard(BuildContext context, NightReport r) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC111634),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B4EE6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EE6).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xCC1D1F48),
              border: Border.all(
                color: const Color(0xFF5B6AC4),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B6AC4).withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.nightlight_round,
                color: Color(0xFFC5CAE9),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Astronomical darkness',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _darkWindows(r),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Image.asset(
              'assets/images/moon_3d.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.nightlight_round,
                color: Color(0xFF9FA8DA),
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestTargetsHeaderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC111634),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B4EE6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EE6).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xCC1D1F48),
              border: Border.all(
                color: const Color(0xFF8E72FF),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E72FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: Color(0xFF8C7CFF),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best targets this night',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ranked by peak astronomy score. Windows use ${c.minimumAltitude.value.round()}° minimum altitude; times use your device timezone.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(TargetPlan t, {bool tonight = false}) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCC0D1427),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF1E2B4E),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                Get.toNamed(AppRoutes.objectDetail, arguments: t.object.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ObjectThumbnail(
                  id: t.object.id,
                  name: t.object.name,
                  size: 46,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 14,
                          )),
                      const SizedBox(height: 3),
                      Text(
                          tonight
                              ? (t.bestWindow == null
                                  ? 'No window'
                                  : '${clockTime(t.bestWindow!.start)} – ${clockTime(t.bestWindow!.end)}')
                              : '${t.now.altitude.toStringAsFixed(1)}° ${t.now.direction} • ${t.object.type}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ))
                    ])),
                IconButton(
                    tooltip: c.favorites.contains(t.object.id)
                        ? 'Remove from saved'
                        : 'Save target',
                    onPressed: () => c.toggleFavorite(t.object.id),
                    icon: Icon(
                      c.favorites.contains(t.object.id)
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: c.favorites.contains(t.object.id)
                          ? const Color(0xFF82B1FF)
                          : AppColors.textSecondary,
                    )),
                const SizedBox(width: 4),
                ScoreRing(score: tonight ? t.nightScore : t.score, size: 44),
              ]),
            ),
          ),
        ),
      ));

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

  Widget _horizonHeaderCard(BuildContext context, NightReport r) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC111634),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B4EE6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EE6).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xCC1D1F48),
              border: Border.all(
                color: const Color(0xFF8E72FF),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E72FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: _GlowRadarReticleIcon(size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horizon Star Chart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'North up · East right · Center = Zenith (90°)\n'
                  'Outer edge = Horizon (0°)\n'
                  'Showing calculated sky for ${clockTime(r.time)}\n'
                  'at ${c.site.value?.name ?? "Remote Dark-Sky Site"}.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _majorNamedObjects = {
    'Polaris', 'Sirius', 'Vega', 'Arcturus', 'Capella', 'Rigel', 'Betelgeuse',
    'Procyon', 'Aldebaran', 'Pollux', 'Castor', 'Spica', 'Deneb', 'Altair', 'Antares',
    'Mars', 'Jupiter', 'Venus', 'Saturn', 'Mercury',
    'M31', 'M42', 'M45', 'M13', 'M33', 'M8', 'M27', 'M57', 'M51', 'M101', 'M1',
    'M34', 'M92', 'M102', 'M103', 'M44', 'M5', 'M79', 'M83', 'M93', 'M68',
    'NGC 884', 'NGC 869', 'NGC 7000', 'NGC 3242', 'NGC 3132', 'NGC 5128',
    'NGC 6635', 'NGC 2333', 'NGC 3628',
  };

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
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.25),
                  border: Border.all(
                    color: const Color(0xFFFFC107),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  size: 14,
                  color: Color(0xFFFFE082),
                ),
              ),
              if (c.skyShowLabels.value)
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: Text(
                    'Moon ${(r.moonIllumination * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFD54F),
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                        Shadow(color: Colors.black, blurRadius: 7),
                      ],
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

    final isPlanet = t.object.isPlanet;
    final isMajor = isPlanet ||
        _majorNamedObjects.contains(t.object.id) ||
        _majorNamedObjects.contains(t.object.name) ||
        c.skyFilter.value != 'All';

    final showLabel = c.skyShowLabels.value && (isSelected || isMajor);
    final dotSize = isSelected ? 10.0 : (isPlanet ? 8.5 : (isMajor ? 6.5 : 5.0));

    final labelText = (t.object.name.isNotEmpty &&
            !t.object.name.startsWith('NGC') &&
            !t.object.name.startsWith('IC'))
        ? t.object.name
        : t.object.id;

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
          height: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: dotSize + (isSelected ? 10 : 4),
                height: dotSize + (isSelected ? 10 : 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? color.withValues(alpha: 0.25)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                ),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isPlanet
                        ? RadialGradient(
                            colors: t.object.id == 'Mars'
                                ? const [Color(0xFFFF8A80), Color(0xFFD50000)]
                                : (t.object.id == 'Venus'
                                    ? const [Color(0xFFFFF9C4), Color(0xFFFFB300)]
                                    : const [Color(0xFFFFE082), Color(0xFFFF9800)]),
                          )
                        : null,
                    color: isPlanet ? null : color,
                    boxShadow: [
                      BoxShadow(
                        color: (isPlanet
                                ? (t.object.id == 'Mars'
                                    ? const Color(0xFFFF5252)
                                    : (t.object.id == 'Venus'
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFFFFB020)))
                                : color)
                            .withValues(alpha: isSelected ? 0.95 : 0.75),
                        blurRadius: isSelected ? 12 : (isMajor ? 7 : 3),
                        spreadRadius: isSelected ? 2.5 : (isMajor ? 1.2 : 0),
                      )
                    ],
                  ),
                ),
              ),
              if (showLabel)
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: Text(
                    labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isPlanet ? 10.0 : (isMajor ? 8.5 : 7.5),
                      fontWeight:
                          isSelected || isPlanet ? FontWeight.w800 : FontWeight.w600,
                      color: isPlanet
                          ? (t.object.id == 'Mars'
                              ? const Color(0xFFFF5252)
                              : (t.object.id == 'Venus'
                                  ? const Color(0xFFFFD54F)
                                  : const Color(0xFFFFB74D)))
                          : (isMajor ? Colors.white : color),
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4),
                        Shadow(color: Colors.black, blurRadius: 7),
                      ],
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xDD0D152E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF243358), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF8A9BB8),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
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
  const HorizonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 24;

    // 1. Celestial background sphere
    final skyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF0F172C),
          Color(0xFF090E1D),
          Color(0xFF04060E),
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, skyPaint);

    // 2. Ethereal Milky Way galaxy glow across the sky disc
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.58);
    final mwPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x339D71FD),
          const Color(0x224D8BFF),
          const Color(0x12FF6584),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromCenter(
          center: Offset.zero, width: radius * 1.85, height: radius * 0.75));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: radius * 1.85, height: radius * 0.75),
        mwPaint);
    canvas.restore();

    // 3. Faint background stars for deep space immersion
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 70; i++) {
      final angle = (i * 137.5) * math.pi / 180.0;
      final dist = (math.sin(i * 47.0).abs()) * (radius - 10);
      final sx = center.dx + dist * math.cos(angle);
      final sy = center.dy + dist * math.sin(angle);
      final alpha =
          (0.2 + (math.cos(i * 29.0).abs() * 0.55)).clamp(0.15, 0.75);
      final rStar = (0.7 + (math.sin(i * 13.0).abs() * 0.7)).clamp(0.6, 1.3);
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(sx, sy), rStar, starPaint);
    }

    // 4. Concentric altitude circles (30°, 60°)
    final gridLinePaint = Paint()
      ..color = const Color(0xFF384B70).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    _drawDashedCircle(canvas, center, radius * 2 / 3, gridLinePaint);
    _drawDashedCircle(canvas, center, radius * 1 / 3, gridLinePaint);

    // Crosshairs: Meridian (N-S) and Prime Vertical (E-W)
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), gridLinePaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), gridLinePaint);

    // Center Zenith crosshair
    final zenithPaint = Paint()
      ..color = const Color(0xFF6A7BFF).withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(center.dx - 5, center.dy),
        Offset(center.dx + 5, center.dy), zenithPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 5),
        Offset(center.dx, center.dy + 5), zenithPaint);

    // 5. Altitude ring labels
    final altPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final alt in [
      (radius * 2 / 3, '30°'),
      (radius * 1 / 3, '60°'),
    ]) {
      altPainter.text = TextSpan(
        text: alt.$2,
        style: TextStyle(
          color: const Color(0xFF7A8BA8).withValues(alpha: 0.65),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
      altPainter.layout();
      altPainter.paint(
          canvas, Offset(center.dx + 5, center.dy - alt.$1 - 10));
    }

    // 6. Glowing outer horizon ring
    final glowPaint = Paint()
      ..color = const Color(0xFF5B67CA).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(center, radius, glowPaint);

    final ringPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF5B67CA),
          Color(0xFF00E5A3),
          Color(0xFF7A88FF),
          Color(0xFF8C52FF),
          Color(0xFF5B67CA),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, ringPaint);

    // 7. Luminous Cardinal Direction Letters
    for (final entry in {
      'N': Offset(center.dx - 6, center.dy - radius - 22),
      'E': Offset(center.dx + radius + 8, center.dy - 8),
      'S': Offset(center.dx - 5, center.dy + radius + 6),
      'W': Offset(center.dx - radius - 20, center.dy - 8),
    }.entries) {
      final isNorth = entry.key == 'N';
      final t = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: isNorth ? const Color(0xFF5CE1E6) : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            shadows: [
              Shadow(
                color: isNorth
                    ? const Color(0xFF5CE1E6).withValues(alpha: 0.8)
                    : const Color(0xFF7A88FF).withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, entry.value);
    }
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 48;
    const dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ForestHorizonSilhouettePainter extends CustomPainter {
  const ForestHorizonSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF04060E)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);

    const pines = [
      (0.02, 14.0),
      (0.05, 20.0),
      (0.08, 12.0),
      (0.12, 24.0),
      (0.15, 16.0),
      (0.18, 11.0),
      (0.22, 19.0),
      (0.26, 26.0),
      (0.30, 15.0),
      (0.34, 21.0),
      (0.38, 13.0),
      (0.42, 18.0),
      (0.46, 23.0),
      (0.50, 14.0),
      (0.54, 20.0),
      (0.58, 25.0),
      (0.62, 16.0),
      (0.66, 22.0),
      (0.70, 12.0),
      (0.74, 19.0),
      (0.78, 24.0),
      (0.82, 15.0),
      (0.86, 22.0),
      (0.90, 17.0),
      (0.94, 21.0),
      (0.98, 14.0),
      (1.0, 17.0),
    ];

    double currentX = 0;
    for (final pine in pines) {
      final targetX = pine.$1 * size.width;
      final height = pine.$2;
      final midX = (currentX + targetX) / 2;
      path.lineTo(currentX, size.height - 5);
      path.lineTo(midX, size.height - height);
      path.lineTo(targetX, size.height - 5);
      currentX = targetX;
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowRadarReticleIcon extends StatelessWidget {
  const _GlowRadarReticleIcon({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GlowRadarReticlePainter(),
    );
  }
}

class _GlowRadarReticlePainter extends CustomPainter {
  const _GlowRadarReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Glowing reticle ring
    final ringPaint = Paint()
      ..color = const Color(0xFFC7B3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 3, ringPaint);

    // 4 crosshair tick marks (N, S, E, W)
    final tickPaint = Paint()
      ..color = const Color(0xFFEDE7F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, 5), tickPaint);
    canvas.drawLine(Offset(center.dx, size.height - 5),
        Offset(center.dx, size.height), tickPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(5, center.dy), tickPaint);
    canvas.drawLine(Offset(size.width - 5, center.dy),
        Offset(size.width, center.dy), tickPaint);

    // Center 4-point sparkling star
    final starPath = Path();
    final starR = radius * 0.42;
    starPath.moveTo(center.dx, center.dy - starR);
    starPath.quadraticBezierTo(
        center.dx, center.dy, center.dx + starR, center.dy);
    starPath.quadraticBezierTo(
        center.dx, center.dy, center.dx, center.dy + starR);
    starPath.quadraticBezierTo(
        center.dx, center.dy, center.dx - starR, center.dy);
    starPath.quadraticBezierTo(
        center.dx, center.dy, center.dx - starR, center.dy);
    starPath.close();

    final starFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
