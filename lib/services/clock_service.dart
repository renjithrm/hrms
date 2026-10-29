// lib/services/clock_service.dart

import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../app/config/app_config.dart';
import '../extensions/date_time_extensions.dart';

/// Single source of "now" and of the company's working day.
///
/// Everything that needs the current time asks this service, so tests can
/// replace it with a fixed clock.
class ClockService {
  /// Creates the clock. [now] and [timezone] exist for tests.
  ClockService({DateTime Function()? now, String? timezone})
      : _now = now ?? DateTime.now {
    _ensureTimezones();
    _location = tz.getLocation(timezone ?? AppConfig.current.companyTimezone);
  }

  static bool _timezonesLoaded = false;

  final DateTime Function() _now;
  late tz.Location _location;

  /// IANA name of the company timezone in use.
  String get timezoneName => _location.name;

  /// Switches to the timezone sent by the server, if it is a known zone.
  void useTimezone(String name) {
    try {
      _location = tz.getLocation(name);
    } on tz.LocationNotFoundException {
      // Keep the configured zone; an unknown name must not break the day.
    }
  }

  /// Current instant in UTC.
  DateTime nowUtc() => _now().toUtc();

  /// Current wall-clock time in the company timezone.
  DateTime companyNow() => toCompany(nowUtc());

  /// Short name of the company timezone right now, for example "IST".
  String get timezoneAbbreviation =>
      tz.TZDateTime.from(nowUtc(), _location).timeZoneName;

  /// [instant] expressed in the company timezone.
  DateTime toCompany(DateTime instant) =>
      tz.TZDateTime.from(instant, _location);

  /// Today's date in the company timezone, as a UTC-midnight date.
  DateTime companyToday() => companyNow().dateOnly;

  /// Company-timezone working day that [instant] belongs to, `yyyy-MM-dd`.
  String workDateOf(DateTime instant) => toCompany(instant).dateOnly.isoDate;

  static void _ensureTimezones() {
    if (_timezonesLoaded) return;
    tz_data.initializeTimeZones();
    _timezonesLoaded = true;
  }
}
