// lib/app/config/dev_config.dart

import 'app_config.dart';
import 'environment.dart';

/// Configuration for development: the mock API in `mock_server/`, locally
/// (`http://localhost:3001`) or through a tunnel.
///
/// For a local server on an Android emulator or device, run
/// `adb reverse tcp:3001 tcp:3001` once so `localhost` reaches the host.
const devConfig = AppConfig(
  environment: Environment.dev,
  appName: 'REBS Dev',
  apiBaseUrl: 'https://undoing-public-carry.ngrok-free.dev',
  officeLatitude: 10.015199435149293,
  officeLongitude: 76.28462335980171,
  officeRadiusMetres: 200,
  companyTimezone: 'Asia/Kolkata',
  isDevSettingsEnabled: true,
);
