import 'package:astrofield_ui/models/astro_target.dart';
import 'package:astrofield_ui/widgets/object_thumbnail.dart';
import 'package:astrofield_ui/widgets/target_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveObjectThumbnail', () {
    test('resolves direct Messier numbers correctly', () {
      expect(resolveObjectThumbnail(id: 'M1'), 'assets/catalog/thumbnails/M1.jpg');
      expect(resolveObjectThumbnail(catalog: 'M42'), 'assets/catalog/thumbnails/M42.jpg');
      expect(resolveObjectThumbnail(name: 'Messier 31'), 'assets/catalog/thumbnails/M31.jpg');
      expect(resolveObjectThumbnail(id: 'm13'), 'assets/catalog/thumbnails/M13.jpg');
      expect(resolveObjectThumbnail(name: 'M 51'), 'assets/catalog/thumbnails/M51.jpg');
    });

    test('resolves NGC aliases to Messier thumbnails', () {
      expect(resolveObjectThumbnail(id: 'NGC 1976'), 'assets/catalog/thumbnails/M42.jpg');
      expect(resolveObjectThumbnail(id: 'NGC1952'), 'assets/catalog/thumbnails/M1.jpg');
      expect(resolveObjectThumbnail(id: 'NGC 224'), 'assets/catalog/thumbnails/M31.jpg');
      expect(resolveObjectThumbnail(id: 'NGC 5272'), 'assets/catalog/thumbnails/M3.jpg');
      expect(resolveObjectThumbnail(id: 'NGC 5904'), 'assets/catalog/thumbnails/M5.jpg');
    });

    test('resolves IC aliases to Messier thumbnails', () {
      expect(resolveObjectThumbnail(id: 'IC 4715'), 'assets/catalog/thumbnails/M24.jpg');
      expect(resolveObjectThumbnail(id: 'IC4725'), 'assets/catalog/thumbnails/M25.jpg');
    });

    test('returns null for non-Messier or non-existent numbers', () {
      expect(resolveObjectThumbnail(id: 'M999'), isNull);
      expect(resolveObjectThumbnail(id: 'NGC 7000'), isNull);
      expect(resolveObjectThumbnail(id: 'Jupiter'), isNull);
      expect(resolveObjectThumbnail(), isNull);
    });
  });

  group('ObjectThumbnail widget', () {
    testWidgets('renders fallback icon when no thumbnail exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectThumbnail(
              id: 'NGC 7000',
              fallbackIcon: Icons.blur_on_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.blur_on_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders Image.asset when Messier thumbnail exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObjectThumbnail(
              id: 'M1',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('TargetTile renders ObjectThumbnail for Messier targets', (tester) async {
      final target = AstroTarget(
        catalog: 'M1',
        name: 'Crab Nebula',
        type: 'Supernova remnant',
        constellation: 'Taurus',
        score: 90,
        altitude: 45.0,
        azimuth: 'E',
        bestWindow: '10:00 PM - 02:00 AM',
        magnitude: 8.4,
        accent: const Color(0xFF4D8BFF),
        icon: Icons.flare_rounded,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetTile(target: target),
          ),
        ),
      );

      expect(find.byType(ObjectThumbnail), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
