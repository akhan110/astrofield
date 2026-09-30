import 'package:astrofield_ui/models/astro_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('best imaging window duration handles midnight rollover', () {
    const orionNebula = AstroTarget(
      catalog: 'M42',
      name: 'Orion Nebula',
      type: 'Nebula',
      constellation: 'Orion',
      score: 96,
      altitude: 68,
      azimuth: 'SE',
      bestWindow: '10:10 PM - 03:18 AM',
      magnitude: 4.0,
      accent: Color(0xFF4D8BFF),
      icon: Icons.blur_on_rounded,
    );

    expect(orionNebula.bestWindowDuration, '5h 08m');
  });

  test('each target derives its own imaging window duration', () {
    const pleiades = AstroTarget(
      catalog: 'M45',
      name: 'Pleiades',
      type: 'Open cluster',
      constellation: 'Taurus',
      score: 94,
      altitude: 73,
      azimuth: 'E',
      bestWindow: '8:48 PM - 01:16 AM',
      magnitude: 1.6,
      accent: Color(0xFF00E5A3),
      icon: Icons.auto_awesome_rounded,
    );

    expect(pleiades.bestWindowDuration, '4h 28m');
  });
}
