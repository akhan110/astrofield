import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/field_models.dart';
import '../models/astro_object.dart';
import '../services/astronomy_engine.dart';
import '../services/field_store.dart';
import '../services/weather_service.dart';

class FieldController extends GetxController {
  FieldController(this.store);
  final FieldStore store;
  final site = Rxn<Site>();
  final report = Rxn<NightReport>();
  final time = DateTime.now().toUtc().obs;
  final live = true.obs;
  final busy = false.obs, locating = false.obs, syncing = false.obs;
  final message = ''.obs;
  final minimumAltitude = 30.0.obs;
  final redMode = false.obs;
  final favorites = <String>{}.obs;
  final planned = <String>{}.obs;
  final equipment = <Equipment>[].obs;
  final activeEquipment = 0.obs;
  final weather = Rxn<WeatherCache>();
  final query = ''.obs;
  final skyFilter = 'All'.obs;
  final skyShowLabels = true.obs;
  final skyMinAltitude = 0.0.obs;
  final selectedSkyTargetId = Rxn<String>();
  final selectedSkyObject = Rxn<AstroObject>();

  bool matchesSkyFilter(TargetPlan t) {
    if (t.now.altitude < skyMinAltitude.value) return false;
    final f = skyFilter.value;
    if (f == 'All') return true;
    if (f == 'Messier') return RegExp(r'^M\d+$').hasMatch(t.object.id);
    if (f == 'Nebulae') return t.object.type.toLowerCase().contains('nebula');
    if (f == 'Galaxies') return t.object.type.toLowerCase().contains('galaxy');
    if (f == 'Clusters') return t.object.type.toLowerCase().contains('cluster');
    if (f == 'Planets') return t.object.type == 'Planet';
    if (f == 'Stars') return t.object.type == 'Star';
    if (f == 'High (>30°)') return t.now.altitude >= 30.0;
    if (f == 'Saved') return favorites.contains(t.object.id);
    return true;
  }
  Timer? _timer;
  int _generation = 0;

  Future<void> initialize() async {
    try {
      await store.initialize();
      final j = store.read('field.v1');
      if (j != null) {
        if (j['site'] != null) {
          final s = Site.fromJson(j['site'] as Map<String, dynamic>);
          if (s.valid) site.value = s;
        }
        favorites.addAll((j['favorites'] as List? ?? []).cast<String>());
        planned.addAll((j['planned'] as List? ?? []).cast<String>());
        minimumAltitude.value =
            ((j['minimumAltitude'] as num?)?.toDouble() ?? 30).clamp(5, 80);
        redMode.value = j['redMode'] == true;
        equipment.addAll((j['equipment'] as List? ?? [])
            .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
            .where((e) => e.valid));
        activeEquipment.value = ((j['activeEquipment'] as num?)?.toInt() ?? 0)
            .clamp(0, equipment.isEmpty ? 0 : equipment.length - 1);
      }
      final cache = store.read('weather.v1');
      if (cache != null) weather.value = WeatherCache.fromJson(cache);
      site.value ??=
          const Site(24.8607, 67.0011, name: 'Remote Dark-Sky Site', elevation: 15);
      if (favorites.isEmpty) favorites.addAll(['M42', 'M45', 'M31']);
    } catch (_) {
      message.value =
          'Some saved data could not be loaded. Check your location and settings.';
    }
    await refresh();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (live.value && !busy.value) {
        time.value = DateTime.now().toUtc();
        refresh();
      }
    });
  }

  Future<void> persist() async {
    try {
      await store.write('field.v1', {
        'site': site.value?.toJson(),
        'favorites': favorites.toList(),
        'planned': planned.toList(),
        'equipment': equipment.map((e) => e.toJson()).toList(),
        'activeEquipment': activeEquipment.value,
        'minimumAltitude': minimumAltitude.value,
        'redMode': redMode.value
      });
    } catch (_) {
      message.value =
          'Could not save changes to this device. Keep the app open and retry.';
    }
  }

  Future<void> setSite(Site value) async {
    if (!value.valid) {
      message.value = 'Enter valid latitude, longitude and elevation.';
      return;
    }
    site.value = value;
    report.value = null;
    await persist();
    await refresh();
  }

  Future<void> gps() async {
    if (locating.value) return;
    locating.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
            'Enable location services or enter coordinates manually.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
            'Location permission unavailable. Enable it in device settings or enter coordinates manually.');
      }
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 25)));
      await setSite(Site(p.latitude, p.longitude,
          elevation: p.altitude.isFinite ? p.altitude.clamp(-500, 10000) : 0,
          name: 'GPS site (accuracy ${p.accuracy.round()} m)'));
    } catch (e) {
      message.value = 'GPS unavailable: $e';
    } finally {
      locating.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    final s = site.value;
    if (s == null) return;
    final generation = ++_generation;
    busy.value = true;
    try {
      final result = await compute(calculateNight,
          CalculationRequest(s, time.value, minimumAltitude.value));
      if (generation == _generation) report.value = result;
    } catch (_) {
      if (generation == _generation) {
        report.value = null;
        message.value =
            'Astronomy calculation failed. Check location and date, then retry.';
      }
    } finally {
      if (generation == _generation) busy.value = false;
    }
  }

  void toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    persist();
  }

  void togglePlan(String id) {
    planned.contains(id) ? planned.remove(id) : planned.add(id);
    persist();
  }

  Equipment? get selectedEquipment => equipment.isEmpty
      ? null
      : equipment[activeEquipment.value.clamp(0, equipment.length - 1)];
  List<TargetPlan> targets(
      {bool tonight = false, bool saved = false, bool search = false}) {
    final list = (report.value?.targets ?? <TargetPlan>[])
        .where((t) =>
            (!saved || favorites.contains(t.object.id)) &&
            (!search ||
                '${t.object.id} ${t.object.name} ${t.object.type}'
                    .toLowerCase()
                    .contains(query.value.toLowerCase())))
        .toList();
    list.sort((a, b) => (tonight ? b.nightScore : b.score)
        .compareTo(tonight ? a.nightScore : a.score));
    return list;
  }

  Future<void> syncWeather() async {
    final s = site.value;
    if (s == null || syncing.value) return;
    syncing.value = true;
    try {
      final cache = await WeatherService().fetch(s);
      await store.write('weather.v1', cache.toJson());
      weather.value = cache;
      message.value = 'Forecast downloaded and saved for offline use.';
    } catch (_) {
      message.value =
          'Weather update failed. Any existing cached forecast is preserved.';
    } finally {
      syncing.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
