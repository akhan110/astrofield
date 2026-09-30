import 'package:astrofield_ui/controllers/favorites_controller.dart';
import 'package:astrofield_ui/data/catalog.dart';
import 'package:astrofield_ui/models/astro_target.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('a saved target can be removed and restored', () {
    final controller = Get.put(FavoritesController());
    final target = AstroTarget.fromCatalogObject(
      fieldCatalog.firstWhere((o) => o.id == 'M42'),
    );

    expect(controller.isFavorite(target), isTrue);

    controller.setFavorite(target, false);
    expect(controller.isFavorite(target), isFalse);
    expect(controller.favorites.any((t) => t.catalog == target.catalog), isFalse);

    controller.setFavorite(target, true);
    expect(controller.isFavorite(target), isTrue);
    expect(controller.favorites.any((t) => t.catalog == target.catalog), isTrue);
  });

  test('toggle returns the target new saved state', () {
    final controller = Get.put(FavoritesController());
    final target = AstroTarget.fromCatalogObject(
      fieldCatalog.firstWhere((o) => o.id == 'M42'),
    );

    expect(controller.toggle(target), isFalse);
    expect(controller.toggle(target), isTrue);
  });
}
