import 'package:astrofield_ui/controllers/field_controller.dart';
import 'package:astrofield_ui/screens/red_light_tools_screen.dart';
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
  });

  tearDown(Get.reset);

  testWidgets('RedLightToolsScreen renders tabs, flashlight, NPF rule, dew point, and intervalometer',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: RedLightToolsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('Night Tools & Red Light'), findsOneWidget);
    expect(find.textContaining('Dark adaptation'), findsOneWidget);

    // Verify 4 Tab Chips
    expect(find.text('Red Flashlight'), findsOneWidget);
    expect(find.text('NPF Star Rule'), findsOneWidget);
    expect(find.text('Dew Point'), findsOneWidget);
    expect(find.text('Intervalometer'), findsOneWidget);

    // --- Tab 1: Red Light Flashlight ---
    expect(find.text('Tap for Full-Screen Red Flashlight'), findsOneWidget);
    expect(find.text('Red Lamp Brightness'), findsOneWidget);

    // Tap flashlight card to enter full screen
    await tester.tap(find.text('Tap for Full-Screen Red Flashlight'));
    await tester.pumpAndSettle();
    expect(find.text('RED FLASHLIGHT'), findsOneWidget);
    expect(find.text('TAP ANYWHERE TO EXIT'), findsOneWidget);

    // Tap to exit full screen
    await tester.tap(find.text('TAP ANYWHERE TO EXIT'));
    await tester.pumpAndSettle();
    expect(find.text('RED FLASHLIGHT'), findsNothing);

    // Toggle app-wide night-vision switch
    final redSwitch = find.byType(SwitchListTile);
    expect(redSwitch, findsOneWidget);
    await tester.tap(redSwitch);
    await tester.pumpAndSettle();
    expect(controller.redMode.value, isTrue);

    // --- Tab 2: NPF Star Rule ---
    await tester.tap(find.text('NPF Star Rule'));
    await tester.pumpAndSettle();

    expect(find.text('RECOMMENDED PINPOINT EXPOSURE'), findsOneWidget);
    expect(find.textContaining('NPF Rule'), findsWidgets);
    expect(find.textContaining('300 Rule'), findsOneWidget);
    expect(find.textContaining('500 Rule'), findsOneWidget);

    // Adjust focal length slider
    final focalSlider = find.byType(Slider).first;
    await tester.drag(focalSlider, const Offset(50, 0));
    await tester.pumpAndSettle();

    // --- Tab 3: Dew Point Monitor ---
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dew Point'));
    await tester.pumpAndSettle();

    expect(find.textContaining('DEW RISK'), findsOneWidget);
    expect(find.text('Air Temp'), findsOneWidget);
    expect(find.text('Dew Margin'), findsOneWidget);
    expect(find.text('Dew Point'), findsWidgets);

    // Adjust ambient temperature slider
    final tempSlider = find.byType(Slider).first;
    await tester.drag(tempSlider, const Offset(-40, 0));
    await tester.pumpAndSettle();

    // --- Tab 4: Intervalometer Timer ---
    await tester.tap(find.text('Intervalometer'));
    await tester.pumpAndSettle();

    expect(find.text('EXPOSING SUB-FRAME'), findsOneWidget);
    expect(find.text('Start Intervalometer'), findsOneWidget);

    // Select sub length preset 30s
    final chip30 = find.widgetWithText(ChoiceChip, '30s');
    expect(chip30, findsOneWidget);
    await tester.tap(chip30);
    await tester.pumpAndSettle();
    expect(find.text('30s'), findsWidgets);

    // Start timer
    final startBtn = find.text('Start Intervalometer');
    await tester.tap(startBtn);
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);

    // Pause timer
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Start Intervalometer'), findsOneWidget);

    // Reset timer
    final resetBtn = find.text('Reset');
    await tester.tap(resetBtn);
    await tester.pump();
  });
}
