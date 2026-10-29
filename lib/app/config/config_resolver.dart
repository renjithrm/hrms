// lib/app/config/config_resolver.dart

import 'app_config.dart';
import 'dev_config.dart';
import 'prod_config.dart';

/// Returns the [AppConfig] for the Flutter `--flavor` the app was built with.
///
/// [flavor] is the value of `appFlavor` (`package:flutter/services.dart`).
/// It is `null` only when no flavour applies (tests), in which case dev is
/// used, matching `default-flavor` in `pubspec.yaml`. An unrecognised
/// flavour throws instead of silently picking one.
AppConfig resolveConfig(String? flavor) {
  switch (flavor) {
    case null:
    case 'dev':
      return devConfig;
    case 'prod':
      return prodConfig;
    default:
      throw StateError(
        'Unknown flavor "$flavor". Add it to resolveConfig() in '
        'lib/app/config/config_resolver.dart.',
      );
  }
}
