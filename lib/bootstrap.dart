// lib/bootstrap.dart

import 'package:flutter/material.dart';

import 'app/app.bottomsheets.dart';
import 'app/app.locator.dart';
import 'app/config/app_config.dart';
import 'main.dart';

/// Shared start-up for every flavour.
///
/// Records [config] before the locator is set up, so services can read it
/// from their constructors, then performs the Stacked setup and runs the app.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialise(config);
  await setupLocator();
  setupBottomSheetUi();
  runApp(const MainApp());
}
