import 'package:astrofield_ui/controllers/field_controller.dart';
import 'package:astrofield_ui/screens/polar_alignment_screen.dart';
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

  testWidgets('PolarAlignmentScreen renders reticle, switches hemisphere, flips view and simulates time',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: PolarAlignmentScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Polar Alignment Clock'), findsOneWidget);
    expect(find.textContaining('Polaris HA:'), findsOneWidget);

    // Verify Mount Latitude wedge readout
    expect(find.textContaining('Mount Latitude Wedge'), findsOneWidget);

    // Verify Reticle Canvas exists
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify Hemispheres chips
    final southChip = find.text('South (Octans)');
    expect(southChip, findsOneWidget);
    await tester.tap(southChip);
    await tester.pumpAndSettle();

    // Verify it updated to Sigma Octantis
    expect(find.textContaining('Sigma Octantis HA'), findsOneWidget);

    // Switch back to North
    final northChip = find.text('North (Polaris)');
    await tester.tap(northChip);
    await tester.pumpAndSettle();
    expect(find.textContaining('Polaris HA:'), findsOneWidget);

    // Toggle Inverted Optical Finder view switch
    final viewSwitch = find.byType(Switch);
    expect(viewSwitch, findsOneWidget);
    await tester.tap(viewSwitch);
    await tester.pumpAndSettle();
    expect(find.textContaining('Inverted View'), findsOneWidget);

    // Verify time simulation section
    expect(find.text('Simulate Time Tonight'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Change slider value
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();

    // Reset to live
    final resetBtn = find.text('Reset to Now');
    expect(resetBtn, findsOneWidget);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();
    expect(find.text('Live'), findsOneWidget);
  });
}
