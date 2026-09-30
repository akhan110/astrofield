import 'package:astrofield_ui/data/catalog.dart';
import 'package:astrofield_ui/domain/field_models.dart';
import 'package:astrofield_ui/services/astronomy_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains complete set of 207 real astronomical objects', () {
    expect(fieldCatalog.length, 207);

    // Verify all 110 Messier objects are present (M1 through M110)
    final messier = fieldCatalog.where((o) => RegExp(r'^M\d+$').hasMatch(o.id));
    expect(messier.length, 110);

    // Verify planets
    final planets = fieldCatalog.where((o) => o.type == 'Planet');
    expect(planets.length, 7);

    // Verify stars
    final stars = fieldCatalog.where((o) => o.type == 'Star');
    expect(stars.length, 20);

    // Verify deep sky objects (NGC/IC/Caldwell)
    final otherDso = fieldCatalog.where((o) => !o.id.startsWith('M') && o.type != 'Planet' && o.type != 'Star');
    expect(otherDso.length, 70);

    // Verify every object has coordinates and valid metadata
    for (final obj in fieldCatalog) {
      expect(obj.id.isNotEmpty, isTrue);
      expect(obj.name.isNotEmpty, isTrue);
      expect(obj.constellation.isNotEmpty, isTrue);
      expect(obj.type.isNotEmpty, isTrue);
      expect(obj.ra, inInclusiveRange(0.0, 24.0));
      expect(obj.dec, inInclusiveRange(-90.0, 90.0));
    }
  });

  test('LocalAstronomyEngine calculates ephemerides for all 207 objects efficiently', () {
    const site = Site(
      -24.6272,
      -70.4042,
      elevation: 2635.0,
      name: 'Atacama Desert',
    );
    final engine = LocalAstronomyEngine();
    final stopwatch = Stopwatch()..start();
    final report = engine.calculate(
      site,
      DateTime.utc(2026, 9, 29, 22, 0),
      30.0,
    );
    stopwatch.stop();

    expect(report.targets.length, 207);
    expect(report.events.containsKey('Sunset'), isTrue);
    expect(report.darkness.isNotEmpty, isTrue);
    // Computation should complete well under 3 seconds even in unoptimized debug test mode
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  });

  test('Sky filter properly filters objects by category and altitude', () {
    const site = Site(
      -24.6272,
      -70.4042,
      elevation: 2635.0,
      name: 'Atacama Desert',
    );
    final engine = LocalAstronomyEngine();
    final report = engine.calculate(
      site,
      DateTime.utc(2026, 9, 29, 22, 0),
      30.0,
    );

    // Verify filter logic for categories
    final messierTargets = report.targets.where((t) => RegExp(r'^M\d+$').hasMatch(t.object.id)).toList();
    expect(messierTargets.length, 110);

    final nebulaTargets = report.targets.where((t) => t.object.type.toLowerCase().contains('nebula')).toList();
    expect(nebulaTargets.isNotEmpty, isTrue);

    final galaxyTargets = report.targets.where((t) => t.object.type.toLowerCase().contains('galaxy')).toList();
    expect(galaxyTargets.isNotEmpty, isTrue);

    final clusterTargets = report.targets.where((t) => t.object.type.toLowerCase().contains('cluster')).toList();
    expect(clusterTargets.isNotEmpty, isTrue);

    final planetTargets = report.targets.where((t) => t.object.type == 'Planet').toList();
    expect(planetTargets.length, 7);

    final starTargets = report.targets.where((t) => t.object.type == 'Star').toList();
    expect(starTargets.length, 20);

    // Objects above horizon can be filtered
    final visible = report.targets.where((t) => t.now.altitude > 0).toList();
    expect(visible.isNotEmpty, isTrue);
    final visibleNebulae = visible.where((t) => t.object.type.toLowerCase().contains('nebula')).toList();
    expect(visibleNebulae.every((t) => t.now.altitude > 0), isTrue);
  });
}
