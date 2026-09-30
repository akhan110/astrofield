import 'dart:async';
import 'package:get/get.dart';
import '../data/astro_object_repository.dart';
import '../models/astro_object.dart';
import 'field_controller.dart';

class ObjectCatalogController extends GetxController {
  ObjectCatalogController({this.savedOnly = false});
  final bool savedOnly;
  final field = Get.find<FieldController>();
  AstroObjectRepository? repository;
  final objects = <AstroObject>[].obs;
  final searchQuery = ''.obs;
  final selectedType = Rxn<AstroObjectType>();
  final selectedConstellation = RxnString();
  final maxMagnitude = RxnDouble();
  final minAltitude = RxnDouble();
  final visibleNow = false.obs;
  final sort = CatalogSort.designation.obs;
  final constellations = <String>[].obs;
  final isLoading = false.obs, isLoadingMore = false.obs, hasMore = true.obs;
  final error = ''.obs;
  final total = 0.obs;
  final savedIds = <String>{}.obs;
  int _offset = 0, _generation = 0;
  Timer? _debounce;
  late final Worker _siteWorker, _timeWorker;
  static const pageSize = 50;

  @override
  void onInit() {
    super.onInit();
    _siteWorker = ever(field.site, (_) {
      if (_needsPositions) reload();
    });
    _timeWorker = ever(field.time, (_) {
      if (_needsPositions) reload();
    });
    initialize();
  }

  bool get _needsPositions =>
      visibleNow.value ||
      minAltitude.value != null ||
      sort.value == CatalogSort.altitude ||
      sort.value == CatalogSort.transit;

  Future<void> initialize() async {
    try {
      repository = await AstroObjectRepository.shared();
      constellations.assignAll(await repository!.constellations());
      // Migrate saved IDs from the earlier preference store to canonical SQLite IDs.
      for (final oldId in field.favorites) {
        final obj = await repository!.getById(oldId);
        if (obj != null && !await repository!.isFavorite(obj.id)) {
          await repository!.setFavorite(obj.id, true);
        }
      }
      savedIds.assignAll(await repository!.favoriteIds());
      await reload();
    } catch (_) {
      error.value =
          'Catalog database unavailable. Restart the app or reinstall the bundled catalog.';
    }
  }

  CatalogFilter get filter => CatalogFilter(
      query: searchQuery.value,
      types: selectedType.value == null ? [] : [selectedType.value!],
      constellation: selectedConstellation.value,
      maxMagnitude: maxMagnitude.value,
      minAltitude: minAltitude.value,
      visibleNow: visibleNow.value,
      savedOnly: savedOnly,
      cacheKey: _needsPositions && field.site.value != null
          ? AstroObjectRepository.cacheKey(field.site.value!, field.time.value)
          : null,
      sort: sort.value);
  void setSearch(String value) {
    searchQuery.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), reload);
  }

  Future<void> reload() async {
    if (repository == null) return;
    final generation = ++_generation;
    _offset = 0;
    hasMore.value = true;
    isLoadingMore.value = false;
    objects.clear();
    isLoading.value = true;
    error.value = '';
    try {
      if (_needsPositions) {
        final site = field.site.value;
        if (site == null) {
          total.value = 0;
          hasMore.value = false;
          error.value = 'Set an observing site to filter or sort by altitude.';
          return;
        }
        await repository!.ensureObservationCache(site, field.time.value);
      }
      savedIds.assignAll(await repository!.favoriteIds());
      total.value = await repository!.countObjects(filter);
      if (generation == _generation) await loadMore();
    } catch (_) {
      if (generation == _generation) {
        error.value = 'Catalog search failed. Change the search or retry.';
      }
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (repository == null || isLoadingMore.value || !hasMore.value) return;
    final generation = _generation;
    isLoadingMore.value = true;
    try {
      final result = await repository!
          .searchObjects(filter, limit: pageSize, offset: _offset);
      if (generation != _generation) return;
      _offset += result.length;
      objects.addAll(result);
      hasMore.value = result.length == pageSize;
    } catch (_) {
      if (generation == _generation) {
        error.value = 'Could not load more objects. Tap retry.';
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleSaved(AstroObject object) async {
    final repo = repository;
    if (repo == null) return;
    final value = !savedIds.contains(object.id);
    try {
      await repo.setFavorite(object.id, value);
      if (value) {
        savedIds.add(object.id);
      } else {
        savedIds.remove(object.id);
      }
      if (savedOnly) {
        objects.removeWhere((o) => o.id == object.id);
        total.value += value ? 1 : -1;
      }
      // Keep existing Saved tab and other screens in sync during migration.
      if (field.favorites.contains(object.designation) != value) {
        field.toggleFavorite(object.designation);
      }
    } catch (_) {
      error.value = 'Could not save this target on your device.';
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _siteWorker.dispose();
    _timeWorker.dispose();
    super.onClose();
  }
}
