import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/services/clock_service.dart';

void main() {
  group('ClockService -', () {
    test('uses the company timezone for the working day', () {
      // 19:00 UTC is 00:30 the next day in India.
      final clock = ClockService(
        now: () => DateTime.utc(2026, 10, 28, 19),
        timezone: 'Asia/Kolkata',
      );
      expect(clock.companyToday(), DateTime.utc(2026, 10, 29));
      expect(clock.workDateOf(clock.nowUtc()), '2026-10-29');
    });

    test('18:29 UTC is still the same day in India', () {
      final clock = ClockService(
        now: () => DateTime.utc(2026, 10, 28, 18, 29),
        timezone: 'Asia/Kolkata',
      );
      expect(clock.workDateOf(clock.nowUtc()), '2026-10-28');
    });

    test('ignores an unknown timezone from the server', () {
      final clock = ClockService(timezone: 'Asia/Kolkata')
        ..useTimezone('Mars/Olympus');
      expect(clock.timezoneName, 'Asia/Kolkata');
    });
  });
}
