/// India Standard Time has no daylight saving, so a fixed offset is exact.
const Duration companyOffset = Duration(hours: 5, minutes: 30);

/// Company timezone name sent to the app.
const String companyTimezone = 'Asia/Kolkata';

/// The company-local calendar date of [instant], as UTC midnight.
DateTime companyDate(DateTime instant) {
  final local = instant.toUtc().add(companyOffset);
  return DateTime.utc(local.year, local.month, local.day);
}

/// UTC instant for [date] at [hour]:[minute] company time.
DateTime companyTime(DateTime date, int hour, int minute) =>
    DateTime.utc(date.year, date.month, date.day, hour, minute)
        .subtract(companyOffset);

/// `yyyy-MM-dd`.
String isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Parses `yyyy-MM-dd`, returning null when malformed.
DateTime? parseIsoDate(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  return DateTime.utc(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
}
