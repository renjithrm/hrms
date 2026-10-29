// lib/app/config/app_config.dart

import 'environment.dart';

/// Immutable, flavour-specific configuration.
///
/// One instance per flavour (`dev_config.dart`, `prod_config.dart`), chosen
/// by `resolveConfig` from the `--flavor` the app was built with and handed
/// to `bootstrap`. Read it through [current].
///
/// Values from `GET /employee/me` (office, timezone) take precedence at
/// runtime; the ones here are used before the first successful load.
///
/// Non-secret values only: anything compiled into the app can be extracted
/// from the binary.
class AppConfig {
  /// Creates a configuration for a single [environment].
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.officeRadiusMetres,
    required this.companyTimezone,
    required this.isDevSettingsEnabled,
  });

  /// The configuration in use by the running app.
  ///
  /// Set once by `bootstrap` before the locator is set up, so services can
  /// read it from their constructors.
  static AppConfig get current {
    final config = _current;
    if (config == null) {
      throw StateError(
        'AppConfig has not been initialised. Start the app through '
        'bootstrap() in main.dart.',
      );
    }
    return config;
  }

  static AppConfig? _current;

  /// Sets the configuration returned by [current].
  static void initialise(AppConfig config) => _current = config;

  /// The environment this build targets.
  final Environment environment;

  /// Human-readable app name. The launcher label is set natively; this
  /// mirrors it for in-app use.
  final String appName;

  /// Base URL of the API, without a trailing slash.
  final String apiBaseUrl;

  /// Office latitude used until the server has provided one.
  final double officeLatitude;

  /// Office longitude used until the server has provided one.
  final double officeLongitude;

  /// Radius around the office inside which attendance is allowed.
  final double officeRadiusMetres;

  /// IANA timezone that defines the company's working day.
  final String companyTimezone;

  /// Whether developer settings (location presets, mock scenarios, clear
  /// today) can be opened by long-pressing the avatar. Decided per flavour,
  /// in any build mode, so a dev release APK for reviewers still has them.
  final bool isDevSettingsEnabled;

  /// Whether this is the development environment.
  bool get isDev => environment == Environment.dev;

  /// Whether this is the production environment.
  bool get isProd => environment == Environment.prod;
}
