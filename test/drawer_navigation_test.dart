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

  testWidgets('AstroDrawer opens from MainShell and navigates to Framing Simulator',
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

    // Verify main shell loaded
    expect(find.text('AstroField'), findsOneWidget);

    // Verify hamburger menu button is present and tap it
    final menuBtn = find.byIcon(Icons.menu_rounded);
    expect(menuBtn, findsOneWidget);
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    // Verify drawer opened with Astro Tools section
    expect(find.text('ASTRO TOOLS'), findsOneWidget);
    expect(find.text('Framing Simulator'), findsOneWidget);
    expect(find.text('Polar Alignment Clock'), findsOneWidget);

    // Tap on Framing Simulator tile in drawer
    final framingTile = find.text('Framing Simulator');
    await tester.tap(framingTile);
    await tester.pumpAndSettle();

    // Verify successfully navigated to Framing Simulator screen
    expect(find.text('Visual Sensor Field of View'), findsOneWidget);
  });
}
