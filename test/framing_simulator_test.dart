import 'dart:math' as math;
import 'package:astrofield_ui/data/catalog.dart';
import 'package:astrofield_ui/domain/field_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Equipment FOV and image scale formulas calculate accurately', () {
    // Test APS-C camera (23.5 x 15.6 mm, 3.76 µm) with 250mm focal length (RedCat 51)
    const eq = Equipment('RedCat 51 + APS-C', 23.5, 15.6, 250.0, 3.76);

    // hFOV = 2 * atan(23.5 / (2 * 250)) * 180 / pi ≈ 5.38°
    expect(eq.horizontalFov, closeTo(5.38, 0.05));

    // vFOV = 2 * atan(15.6 / (2 * 250)) * 180 / pi ≈ 3.57°
    expect(eq.verticalFov, closeTo(3.57, 0.05));

    // imageScale = 206.265 * 3.76 / 250 ≈ 3.10 arcsec/pixel
    expect(eq.imageScale, closeTo(3.10, 0.05));
  });

  test('Framing Simulator handles large and small catalog targets correctly', () {
    // Full Frame (36 x 24 mm) with 1000mm focal length
    const eq = Equipment('1000mm + Full Frame', 36.0, 24.0, 1000.0, 3.76);
    final hFov = eq.horizontalFov; // ~2.06° (123.7 arcmin)
    final vFov = eq.verticalFov;   // ~1.37° (82.5 arcmin)

    // Andromeda (M31) is 177.8 arcminutes (2.96 degrees) -> exceeds sensor FOV
    final m31 = fieldCatalog.firstWhere((o) => o.id == 'M31');
    expect(m31.sizeArcmin, closeTo(178.0, 0.5));
    expect(m31.sizeArcmin / 60.0 > math.max(hFov, vFov), isTrue);

    // Ring Nebula (M57) is ~1.4 arcminutes (0.023 degrees) -> very small deep-sky target
    final m57 = fieldCatalog.firstWhere((o) => o.id == 'M57');
    expect(m57.sizeArcmin, closeTo(1.4, 0.2));
    expect(m57.sizeArcmin / 60.0 < math.min(hFov, vFov) * 0.1, isTrue);

    // Orion Nebula (M42) is 85 arcminutes (1.42 degrees) -> fits within horizontal FOV
    final m42 = fieldCatalog.firstWhere((o) => o.id == 'M42');
    expect(m42.sizeArcmin, 85.0);
    expect(m42.sizeArcmin / 60.0 < hFov, isTrue);
  });
}
