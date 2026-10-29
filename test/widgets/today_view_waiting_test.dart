// Required widget test: with one check-in saved offline, Today shows
// "1 waiting" in the pill and the Waiting chip on today's row.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/models/attendance_day.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/location_reading.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/services/sync_service.dart';
import 'package:rebs_hrms/ui/theme/app_theme.dart';
import 'package:rebs_hrms/ui/views/today/today_view.dart';

import '../helpers/fixtures.dart';
import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';

void main() {
  testWidgets('one pending event: "1 waiting" pill and Waiting chip',
      (tester) async {
    registerServices();
    addTearDown(locator.reset);
    locator
      ..unregister<ClockService>()
      ..registerSingleton<ClockService>(
        ClockService(now: () => testNow, timezone: 'Asia/Kolkata'),
      )
      ..unregister<GeofencePolicy>()
      ..registerSingleton<GeofencePolicy>(GeofencePolicy());

    const position = GeoPosition(
      latitude: 10.0159,
      longitude: 76.3419,
      accuracyMetres: 12,
    );
    final checkInAt = DateTime.utc(2026, 10, 28, 3, 2);
    final pending = AttendanceEvent(
      eventId: 'e1',
      type: AttendanceEventType.checkIn,
      workDate: '2026-10-28',
      occurredAt: checkInAt,
      position: position,
    );
    final today = AttendanceDay(
      workDate: '2026-10-28',
      checkInAt: checkInAt,
      checkInState: SyncState.pending,
    );

    final employees = getAndRegisterEmployeeService();
    when(employees.employee).thenReturn(testEmployee);
    final connectivity = getAndRegisterConnectivityService();
    when(connectivity.isOnline).thenReturn(false);
    when(connectivity.backOnline$).thenAnswer((_) => const Stream.empty());
    final lifecycle = getAndRegisterAppLifecycleService();
    when(lifecycle.resumed$).thenAnswer((_) => const Stream.empty());
    final location = getAndRegisterLocationService();
    when(location.read(any, askPermission: anyNamed('askPermission')))
        .thenAnswer((_) async => const LocationFix(position));

    final attendance = getAndRegisterAttendanceService();
    when(attendance.today).thenReturn(today);
    when(attendance.recent).thenReturn([today]);
    when(attendance.hasCache).thenReturn(true);
    when(attendance.lastUpdated).thenReturn(testNow);
    when(attendance.loadCached()).thenAnswer((_) async {});
    when(attendance.refresh()).thenAnswer((_) async {});
    final leave = getAndRegisterLeaveService();
    when(leave.balances).thenReturn(const []);
    when(leave.loadCached()).thenAnswer((_) async {});
    when(leave.refresh()).thenAnswer((_) async {});

    // The real SyncService decides the pill from the outbox.
    final outbox = getAndRegisterOutboxService();
    when(outbox.recentEvents()).thenAnswer((_) async => [pending]);
    when(outbox.counts()).thenAnswer((_) async => (waiting: 1, rejected: 0));
    final sync = SyncService();
    locator
      ..unregister<SyncService>()
      ..registerSingleton<SyncService>(sync);
    await sync.start();
    addTearDown(sync.stop);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: TodayView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.syncWaiting(1)), findsOneWidget);
    expect(find.text(AppStrings.chipWaiting), findsOneWidget);
  });
}
