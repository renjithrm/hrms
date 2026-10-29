// test/flutter_test_config.dart

import 'dart:async';

import 'package:rebs_hrms/app/config/app_config.dart';
import 'package:rebs_hrms/app/config/dev_config.dart';

/// Runs before every test file: services read [AppConfig.current] in their
/// constructors, as they do after `bootstrap` in the app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.initialise(devConfig);
  await testMain();
}
