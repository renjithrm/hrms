// lib/models/shift.dart

/// A working shift in company local time, for example 09:00 to 18:00.
class Shift {
  /// Creates a shift from minutes after midnight.
  const Shift({required this.startMinutes, required this.endMinutes});

  /// Reads `{"start": "09:00", "end": "18:00"}`.
  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        startMinutes: _parse(json['start'] as String),
        endMinutes: _parse(json['end'] as String),
      );

  /// Shift start, in minutes after local midnight.
  final int startMinutes;

  /// Shift end, in minutes after local midnight.
  final int endMinutes;

  /// Planned length of the shift.
  Duration get length => Duration(minutes: endMinutes - startMinutes);

  /// Start as `HH:mm`.
  String get startLabel => _format(startMinutes);

  /// End as `HH:mm`.
  String get endLabel => _format(endMinutes);

  /// Serialises to the API shape.
  Map<String, dynamic> toJson() => {'start': startLabel, 'end': endLabel};

  static int _parse(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}
