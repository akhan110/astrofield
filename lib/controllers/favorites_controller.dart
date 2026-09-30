import 'package:get/get.dart';

import '../data/catalog.dart';
import '../models/astro_target.dart';
import 'field_controller.dart';

class FavoritesController extends GetxController {
  final RxSet<String> _favoriteCatalogs = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<FieldController>()) {
      _favoriteCatalogs.addAll(Get.find<FieldController>().favorites);
    } else {
      _favoriteCatalogs.addAll(['M42', 'M45', 'M31']);
    }
  }

  List<AstroTarget> get favorites {
    if (Get.isRegistered<FieldController>()) {
      final field = Get.find<FieldController>();
      final report = field.report.value;
      if (report != null && report.targets.isNotEmpty) {
        return report.targets
            .where((t) => _favoriteCatalogs.contains(t.object.id))
            .map((t) => AstroTarget.fromTargetPlan(t, isFavorite: true))
            .toList(growable: false);
      }
    }
    return fieldCatalog
        .where((obj) => _favoriteCatalogs.contains(obj.id))
        .map((obj) => AstroTarget.fromCatalogObject(obj, isFavorite: true))
        .toList(growable: false);
  }

  bool isFavorite(AstroTarget target) =>
      _favoriteCatalogs.contains(target.catalog);

  void setFavorite(AstroTarget target, bool isFavorite) {
    if (isFavorite) {
      _favoriteCatalogs.add(target.catalog);
      if (Get.isRegistered<FieldController>()) {
        Get.find<FieldController>().favorites.add(target.catalog);
      }
    } else {
      _favoriteCatalogs.remove(target.catalog);
      if (Get.isRegistered<FieldController>()) {
        Get.find<FieldController>().favorites.remove(target.catalog);
      }
    }
  }

  bool toggle(AstroTarget target) {
    final isNowFavorite = !isFavorite(target);
    setFavorite(target, isNowFavorite);
    return isNowFavorite;
  }
}
