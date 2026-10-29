import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:rebs_hrms/app/app.router.dart';
import 'package:rebs_hrms/app/config/app_config.dart';
import 'package:rebs_hrms/app/config/config_resolver.dart';
import 'package:rebs_hrms/bootstrap.dart';
import 'package:rebs_hrms/constants/app_colors.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/ui/theme/app_theme.dart';
import 'package:stacked_services/stacked_services.dart';

/// Single entry point for every flavour. The config is chosen from the
/// `--flavor` the app was built with (`appFlavor`).
Future<void> main() => bootstrap(resolveConfig(appFlavor));

/// Root widget: theme and Stacked routing.
class MainApp extends StatelessWidget {
  /// Creates the app.
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
      builder: AppConfig.current.isDev ? _devBanner : null,
    );
  }

  // Corner ribbon so a dev build is never mistaken for prod.
  static Widget _devBanner(BuildContext context, Widget? child) {
    return Banner(
      message: AppStrings.devFlavorBanner,
      location: BannerLocation.topEnd,
      color: Palette.warning,
      textDirection: TextDirection.ltr,
      layoutDirection: TextDirection.ltr,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
