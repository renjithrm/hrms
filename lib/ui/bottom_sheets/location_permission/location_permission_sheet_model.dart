// lib/ui/bottom_sheets/location_permission/location_permission_sheet_model.dart

import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../constants/app_strings.dart';
import '../../../models/location_failure.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';

/// Explains why location is needed and fixes the blocking setting.
class LocationPermissionSheetModel extends BaseViewModel {
  /// Creates the model for [reason].
  LocationPermissionSheetModel(this.reason);

  final _locationService = locator<LocationService>();
  final _logger = locator<LoggerService>();

  /// What is blocking the location.
  final LocationFailure reason;

  /// Sheet title.
  String get title => switch (reason) {
        LocationFailure.denied => AppStrings.locationDenied,
        LocationFailure.deniedForever => AppStrings.locationBlocked,
        LocationFailure.serviceOff => AppStrings.locationServiceOff,
        LocationFailure.unavailable => AppStrings.locationUnavailable,
      };

  /// Numbered steps, shown only when the fix is in system settings.
  List<String> get steps => reason == LocationFailure.deniedForever
      ? const [
          AppStrings.sheetStepOpen,
          AppStrings.sheetStepPermissions,
          AppStrings.sheetStepAllow,
        ]
      : const [];

  /// Label of the main button.
  String get primaryLabel => switch (reason) {
        LocationFailure.denied => AppStrings.actionAllowLocation,
        LocationFailure.deniedForever => AppStrings.sheetOpenSettings,
        LocationFailure.serviceOff => AppStrings.sheetOpenLocationSettings,
        LocationFailure.unavailable => AppStrings.sheetTryAgain,
      };

  /// Opens the right settings page if needed, then closes the sheet with
  /// `confirmed: true` so the caller reads the location again.
  Future<void> onPrimary(void Function(SheetResponse) complete) async {
    try {
      switch (reason) {
        case LocationFailure.deniedForever:
          await _locationService.openAppSettings();
        case LocationFailure.serviceOff:
          await _locationService.openLocationSettings();
        case LocationFailure.denied:
        case LocationFailure.unavailable:
          break;
      }
    } catch (e, stackTrace) {
      _logger.error('Open settings', e, stackTrace);
    }
    complete(SheetResponse(confirmed: true));
  }

  /// Closes the sheet without doing anything.
  void onDismiss(void Function(SheetResponse) complete) =>
      complete(SheetResponse(confirmed: false));
}
