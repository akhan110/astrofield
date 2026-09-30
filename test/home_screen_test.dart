import 'package:astrofield_ui/app/app_pages.dart';
import 'package:astrofield_ui/app/app_routes.dart';
import 'package:astrofield_ui/controllers/field_controller.dart';
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

  testWidgets('HomeScreen matches uploaded UI mockup with cards, buttons, and bottom nav',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.shell,
        getPages: AppPages.pages,
      ),
    );
    await tester.pumpAndSettle();

    // Verify AstroField Header & GPS site subtitle
    expect(find.text('AstroField'), findsOneWidget);
    expect(find.textContaining('GPS site (accuracy 100 m)'), findsOneWidget);

    // Verify Date & Time Pill with device time text
    expect(find.text('device time'), findsOneWidget);

    // Verify "Current sky" card and its elements
    expect(find.text('Current sky'), findsOneWidget);
    expect(find.textContaining('Moon'), findsOneWidget);
    expect(find.textContaining('device timezone'), findsOneWidget);

    // Verify 3 Action Buttons: Catalog, Weather, Equipment
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Equipment'), findsOneWidget);

    // Verify "Best targets now" Card
    expect(find.text('Best targets now'), findsOneWidget);
    expect(
      find.text('Ranked by altitude, darkness and Moon interference. Minimum altitude 30°.'),
      findsOneWidget,
    );

    // Verify Bottom Navigation Bar labels
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sky'), findsOneWidget);
    expect(find.text('Tonight'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Test tapping Sky bottom navigation tab
    await tester.tap(find.text('Sky'));
    await tester.pumpAndSettle();
    expect(find.text('Your sky'), findsOneWidget);

    // Test tapping Tonight tab
    await tester.tap(find.text('Tonight'));
    await tester.pumpAndSettle();
    expect(find.text('Tonight planner'), findsOneWidget);

    // Test tapping Saved tab
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved targets'), findsOneWidget);

    // Test tapping More tab
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Field tools and offline controls'), findsOneWidget);

    // Return to Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('AstroField'), findsOneWidget);
    expect(find.text('Current sky'), findsOneWidget);
  });
}
