// lib/app/config/prod_config.dart

import 'app_config.dart';
import 'environment.dart';

/// Configuration for production.
// TODO(config): replace the placeholder URL with the real production API.
const prodConfig = AppConfig(
  environment: Environment.prod,
  appName: 'REBS Workspace',
  apiBaseUrl: 'https://undoing-public-carry.ngrok-free.dev',
  officeLatitude: 10.0159,
  officeLongitude: 76.3419,
  officeRadiusMetres: 200,
  companyTimezone: 'Asia/Kolkata',
  isDevSettingsEnabled: true,
);
