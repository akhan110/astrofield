import 'package:flutter_test/flutter_test.dart';
import 'package:geoengine/geoengine.dart' as astro;

void main() {
  test('geoengine provides sidereal time and star equatorial calculations', () {
    final utc = DateTime.utc(2026, 9, 29, 21, 0);
    final st = astro.siderealTime(utc);
    expect(st, isNotNull);
    expect(st, inInclusiveRange(0.0, 24.0));

    // Define Polaris
    astro.defineStar(astro.Body.Star1, 2.5303, 89.2641, 1000000);
    final observer = astro.Observer(45.0, 10.0, 0.0);
    final eq = astro.equator(astro.Body.Star1, utc, observer, true, true);
    expect(eq.ra, inInclusiveRange(0.0, 24.0));
    expect(eq.dec, inInclusiveRange(88.0, 90.0));
  });
}
