// lib/app/config/environment.dart

/// The environments the app can be built for.
///
/// Each value maps 1:1 to a native flavour (Android product flavour / iOS
/// scheme) and to one config in `lib/app/config/`.
enum Environment {
  /// Development against the local mock API.
  dev,

  /// Production, as shipped to the stores.
  prod,
}
