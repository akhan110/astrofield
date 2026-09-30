import 'package:get/get.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';
import '../screens/field_screens.dart';
import '../screens/object_catalog_screen.dart';
import '../screens/catalog_detail_screen.dart';
import '../screens/field_forms.dart';
import '../screens/framing_simulator_screen.dart';
import '../screens/polar_alignment_screen.dart';
import '../screens/session_scheduler_screen.dart';
import '../screens/point_to_sky_screen.dart';
import '../screens/red_light_tools_screen.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.shell, page: () => const MainShell()),
    GetPage(name: AppRoutes.search, page: () => const ObjectCatalogScreen()),
    GetPage(
        name: AppRoutes.objectDetail, page: () => const CatalogDetailScreen()),
    GetPage(
        name: AppRoutes.skyChart, page: () => const FieldScreen(FieldPage.sky)),
    GetPage(
        name: AppRoutes.sunTwilight,
        page: () => const FieldScreen(FieldPage.sun)),
    GetPage(
        name: AppRoutes.moon, page: () => const FieldScreen(FieldPage.moon)),
    GetPage(
        name: AppRoutes.weather,
        page: () => const FieldScreen(FieldPage.weather)),
    GetPage(
        name: AppRoutes.location, page: () => const FieldForm(location: true)),
    GetPage(
        name: AppRoutes.tripPack,
        page: () => const FieldScreen(FieldPage.trip)),
    GetPage(
        name: AppRoutes.sync, page: () => const FieldScreen(FieldPage.sync)),
    GetPage(
        name: AppRoutes.equipment,
        page: () => const FieldScreen(FieldPage.equipment)),
    GetPage(name: AppRoutes.equipmentForm, page: () => const FieldForm()),
    GetPage(
        name: AppRoutes.settings,
        page: () => const FieldScreen(FieldPage.settings)),
    GetPage(
        name: AppRoutes.about, page: () => const FieldScreen(FieldPage.about)),
    GetPage(
        name: AppRoutes.framingSimulator,
        page: () => const FramingSimulatorScreen()),
    GetPage(
        name: AppRoutes.polarAlignment,
        page: () => const PolarAlignmentScreen()),
    GetPage(
        name: AppRoutes.sessionScheduler,
        page: () => const SessionSchedulerScreen()),
    GetPage(name: AppRoutes.pointToSky, page: () => const PointToSkyScreen()),
    GetPage(
        name: AppRoutes.redLightTools, page: () => const RedLightToolsScreen()),
  ];
}
