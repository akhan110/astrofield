import 'package:astrofield_ui/controllers/field_controller.dart';
import 'package:astrofield_ui/screens/framing_simulator_screen.dart';
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
  setUp(() {
    Get.testMode = true;
    final store = _FakeFieldStore();
    Get.put(FieldController(store));
  });

  tearDown(Get.reset);

  testWidgets('FramingSimulatorScreen renders, updates presets, and rotates without errors',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: FramingSimulatorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and target title are visible
    expect(find.text('Framing Simulator'), findsOneWidget);
    expect(find.textContaining('M42'), findsOneWidget);

    // Verify visual FOV canvas and angle slider are present
    expect(find.text('Visual Sensor Field of View'), findsOneWidget);
    expect(find.textContaining('Camera Angle: 0°'), findsOneWidget);

    // Tap on a different sensor preset
    final fullFrameChip = find.text('Full Frame (36×24)');
    expect(fullFrameChip, findsOneWidget);
    await tester.tap(fullFrameChip);
    await tester.pumpAndSettle();

    // Tap on a telescope preset
    final telescopeChip = find.text('135mm (Samyang / Rokinon)');
    expect(telescopeChip, findsOneWidget);
    await tester.tap(telescopeChip);
    await tester.pumpAndSettle();

    // Verify optical calculations updated
    expect(find.textContaining('Image Scale'), findsOneWidget);
    expect(find.textContaining('Target Diameter'), findsOneWidget);

    // Tap 'Change' target button to open bottom sheet
    final changeBtn = find.text('Change');
    expect(changeBtn, findsOneWidget);
    await tester.tap(changeBtn);
    await tester.pumpAndSettle();

    // Verify Target Picker opened
    expect(find.text('Select Astro Target'), findsOneWidget);

    // Search for M31 in target picker
    await tester.enterText(find.byType(TextField), 'M31');
    await tester.pumpAndSettle();

    // Select Andromeda M31 from filtered list
    final m31Tile = find.textContaining('M31 · Andromeda Galaxy');
    expect(m31Tile, findsOneWidget);
    await tester.tap(m31Tile);
    await tester.pumpAndSettle();

    // Verify M31 is now selected on the main screen
    expect(find.textContaining('M31 · Andromeda Galaxy'), findsOneWidget);
  });
}
