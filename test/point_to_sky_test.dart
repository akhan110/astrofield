import 'package:astrofield_ui/controllers/field_controller.dart';
import 'package:astrofield_ui/screens/point_to_sky_screen.dart';
import 'package:astrofield_ui/services/astronomy_engine.dart';
import 'package:astrofield_ui/services/field_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeFieldStore implements FieldStore {
  final Map<String, dynamic> data = {};

  @override
  Future<void> initialize() async {}

  @override
  Map<String, dynamic>? read(String key) => data[key];

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    data[key] = value;
  }
}

void main() {
  late FieldController controller;

  setUp(() async {
    Get.testMode = true;
    final store = _FakeFieldStore();
    controller = FieldController(store);
    Get.put(controller);
    await controller.initialize();
    final engine = LocalAstronomyEngine();
    controller.report.value = engine.calculate(
      controller.site.value!,
      DateTime.utc(2026, 10, 15, 21, 0),
      30.0,
    );
  });

  tearDown(Get.reset);

  testWidgets('PointToSkyScreen renders AR sky, navigates directions, locks targets and toggles red mode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: PointToSkyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Point-to-Sky Compass'), findsOneWidget);
    expect(find.textContaining('Interactive AR'), findsOneWidget);

    // Verify canvas exists
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify coordinates bar at bottom
    expect(find.textContaining('Azimuth:'), findsOneWidget);
    expect(find.textContaining('Altitude:'), findsOneWidget);

    // Tap cardinal direction chip 'N'
    final northChip = find.widgetWithText(ActionChip, 'N');
    expect(northChip, findsOneWidget);
    await tester.tap(northChip);
    await tester.pumpAndSettle();
    expect(find.textContaining('Azimuth: 0.0°'), findsOneWidget);

    // Tap cardinal direction chip 'E'
    final eastChip = find.widgetWithText(ActionChip, 'E');
    expect(eastChip, findsOneWidget);
    await tester.tap(eastChip);
    await tester.pumpAndSettle();
    expect(find.textContaining('Azimuth: 90.0°'), findsOneWidget);

    // Tap Zenith chip
    final zenithChip = find.widgetWithText(ActionChip, 'Zenith (90°)');
    expect(zenithChip, findsOneWidget);
    await tester.tap(zenithChip);
    await tester.pumpAndSettle();
    expect(find.textContaining('Altitude: 89.0°'), findsOneWidget);

    // Test drag panning on the sky canvas
    final canvasFinder = find.byType(GestureDetector).first;
    await tester.drag(canvasFinder, const Offset(-100, 50));
    await tester.pumpAndSettle();

    // Toggle Night-Vision Red Light mode
    final redLightBtn = find.byIcon(Icons.brightness_medium_rounded);
    expect(redLightBtn, findsOneWidget);
    await tester.tap(redLightBtn);
    await tester.pumpAndSettle();

    // Toggle back
    await tester.tap(redLightBtn);
    await tester.pumpAndSettle();

    // Open Target Picker Modal
    final targetPickerBtn = find.byIcon(Icons.track_changes_rounded);
    expect(targetPickerBtn, findsOneWidget);
    await tester.tap(targetPickerBtn);
    await tester.pumpAndSettle();

    // Verify sheet opened
    expect(find.text('Lock Guiding Target'), findsOneWidget);

    // Search for M42
    await tester.enterText(find.byType(TextField), 'M42');
    await tester.pumpAndSettle();

    // Tap on M42 in list
    final m42Tile = find.textContaining('M42 · Orion Nebula');
    expect(m42Tile, findsOneWidget);
    await tester.tap(m42Tile);
    await tester.pumpAndSettle();

    // Verify Radar guidance HUD is active
    expect(find.textContaining('M42'), findsWidgets);

    // Tap 'Center' button in guidance HUD to align exactly onto M42
    final centerBtn = find.text('Center');
    if (centerBtn.evaluate().isNotEmpty) {
      await tester.tap(centerBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('TARGET CENTERED: M42'), findsOneWidget);
    }

    // Test FOV Preset Picker
    final fovChip = find.textContaining('FOV:');
    expect(fovChip, findsOneWidget);
    await tester.tap(fovChip);
    await tester.pumpAndSettle();

    // Verify FOV modal opened
    expect(find.text('Camera Sensor FOV Overlay'), findsOneWidget);

    // Select 50mm Normal preset
    final preset50 = find.text('50mm Normal');
    expect(preset50, findsOneWidget);
    await tester.tap(preset50);
    await tester.pumpAndSettle();

    // Verify updated chip
    expect(find.text('FOV: 50mm (FF)'), findsOneWidget);
  });
}
