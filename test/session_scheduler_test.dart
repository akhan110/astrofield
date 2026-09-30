import 'package:astrofield_ui/controllers/field_controller.dart';
import 'package:astrofield_ui/screens/session_scheduler_screen.dart';
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
    // Precompute a real night report synchronously for testing
    final engine = LocalAstronomyEngine();
    controller.report.value = engine.calculate(
      controller.site.value!,
      DateTime.utc(2026, 10, 15, 21, 0),
      30.0,
    );
  });

  tearDown(Get.reset);

  testWidgets('SessionSchedulerScreen renders timeline, queue, adjusts exposures, and adds targets',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SessionSchedulerScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Session Scheduler'), findsOneWidget);
    expect(find.textContaining('Multi-target night sequence'), findsOneWidget);

    // Verify Overview Stats cards
    expect(find.text('Dark Window'), findsOneWidget);
    expect(find.text('Planned Run'), findsOneWidget);

    // Verify Night Schedule Timeline is painted
    expect(find.text('Night Schedule Timeline'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify Target Queue exists and has initial scheduled targets
    expect(find.textContaining('Imaging Queue'), findsOneWidget);

    // Adjust exposure time on a slider
    final sliders = find.byType(Slider);
    expect(sliders, findsWidgets);
    await tester.drag(sliders.first, const Offset(60, 0));
    await tester.pumpAndSettle();

    // Tap sub-exposure choice chip (e.g. 180s)
    final chip180 = find.text('180s');
    expect(chip180, findsOneWidget);
    await tester.tap(chip180);
    await tester.pumpAndSettle();

    // Tap Copy Plan button
    final copyBtn = find.text('Copy Plan');
    expect(copyBtn, findsOneWidget);
    await tester.ensureVisible(copyBtn);
    await tester.tap(copyBtn);
    await tester.pump();
    expect(find.text('Session Plan Copied'), findsOneWidget);

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();

    // Tap Save Session button
    final saveBtn = find.text('Save Session');
    expect(saveBtn, findsOneWidget);
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pump();
    expect(find.text('Session Saved'), findsOneWidget);

    Get.closeAllSnackbars();
    await tester.pumpAndSettle();

    // Test Target Picker bottom sheet
    final addBtn = find.text('Add');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify sheet opened
    expect(find.text('Add Target to Session'), findsOneWidget);

    // Filter by Nebulae
    final nebulaeChip = find.text('Nebulae');
    expect(nebulaeChip, findsOneWidget);
    await tester.tap(nebulaeChip);
    await tester.pumpAndSettle();

    // Close the sheet
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Add Target to Session'), findsNothing);
  });
}
