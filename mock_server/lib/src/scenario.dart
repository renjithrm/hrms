/// Behaviours reviewers can switch between to exercise the app.
enum Scenario {
  /// Normal responses after a short delay.
  success(Duration(milliseconds: 150)),

  /// Every response takes four seconds but succeeds.
  slow(Duration(seconds: 4)),

  /// Attendance events are saved, then the response is held past the
  /// app's 8 s timeout. Retrying the same event ID returns the original.
  timeoutAfterCommit(Duration(milliseconds: 150)),

  /// Every API call returns HTTP 500.
  serverError(Duration(milliseconds: 150)),

  /// The next check-in finds attendance "already recorded on another
  /// device" and gets HTTP 409.
  attendanceConflict(Duration(milliseconds: 150)),

  /// Leave submissions that pass the normal rules are refused with a
  /// blackout-period error (HTTP 422).
  leaveRejected(Duration(milliseconds: 150));

  const Scenario(this.latency);

  /// Delay added before every API response.
  final Duration latency;

  /// Name used in `/__mock/scenario`, for example `timeout_after_commit`.
  String get wireName => name.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      );

  /// Parses [wireName]; returns null for unknown names.
  static Scenario? fromWire(String value) {
    for (final scenario in values) {
      if (scenario.wireName == value) return scenario;
    }
    return null;
  }
}
