// lib/extensions/date_time_extensions.dart

/// Date helpers. Calendar dates are represented as UTC midnight so that
/// day arithmetic never crosses a daylight-saving change.
extension DateTimeExtensions on DateTime {
  /// This date at UTC midnight, dropping the time of day.
  DateTime get dateOnly => DateTime.utc(year, month, day);

  /// `yyyy-MM-dd`, the format used by the API and the database.
  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  /// `yyyy-MM`, the month key used by `GET /attendance?month=`.
  String get isoMonth => '${year.toString().padLeft(4, '0')}-${_two(month)}';

  /// Whole calendar days from this date to [other], both treated as dates.
  int daysUntil(DateTime other) => other.dateOnly.difference(dateOnly).inDays;

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// Parses a `yyyy-MM-dd` string into a UTC-midnight date.
DateTime parseIsoDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Expected yyyy-MM-dd', value);
  }
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
