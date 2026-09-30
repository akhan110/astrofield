import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/app_pages.dart';
import 'app/app_routes.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/field_controller.dart';
import 'services/field_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(FavoritesController(), permanent: true);
  final field = Get.put(FieldController(FieldStore()), permanent: true);
  field.initialize();
  runApp(const AstroFieldApp());
}

class AstroFieldApp extends StatelessWidget {
  const AstroFieldApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AstroField',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      builder: (context, child) => Obx(() => ColorFiltered(
            colorFilter: Get.find<FieldController>().redMode.value
                ? const ColorFilter.matrix([
                    .18,
                    .55,
                    .07,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ])
                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: child ?? const SizedBox.shrink(),
          )),
    );
  }
}
