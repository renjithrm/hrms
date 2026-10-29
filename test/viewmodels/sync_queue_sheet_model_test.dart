import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/sync_state.dart';
import 'package:rebs_hrms/services/clock_service.dart';
import 'package:rebs_hrms/ui/bottom_sheets/sync_queue/sync_queue_sheet_model.dart';

import '../helpers/real_storage.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_helpers.mocks.dart';

AttendanceEvent _event(
  String id, {
  AttendanceEventType type = AttendanceEventType.checkIn,
  SyncState status = SyncState.pending,
  DateTime? nextAttemptAt,
  String? lastError,
}) =>
    AttendanceEvent(
      eventId: id,
      type: type,
      workDate: '2026-10-28',
      occurredAt: DateTime.utc(2026, 10, 28, 3, 32),
      position: const GeoPosition(
        latitude: 10.0159,
        longitude: 76.3419,
        accuracyMetres: 12,
      ),
      status: status,
      nextAttemptAt: nextAttemptAt,
      lastError: lastError,
    );

void main() {
  group('SyncQueueSheetModel -', () {
    late MockSyncService sync;
    late MockConnectivityService connectivity;

    setUp(() {
      registerServices();
      locator
        ..unregister<ClockService>()
        ..registerSingleton<ClockService>(
          ClockService(now: () => testNow, timezone: 'Asia/Kolkata'),
        );
      sync = getAndRegisterSyncService();
      connectivity = getAndRegisterConnectivityService();
      when(connectivity.isOnline).thenReturn(true);
      when(sync.queue).thenReturn(const []);
      when(sync.syncNow(ignoreBackoff: anyNamed('ignoreBackoff')))
          .thenAnswer((_) async {});
    });

    tearDown(() => locator.reset());

    test('empty queue says nothing has been recorded', () {
      final model = SyncQueueSheetModel();

      expect(model.rows, isEmpty);
      expect(model.subtitle, AppStrings.syncSheetEmpty);
      expect(model.canSyncNow, isFalse);
    });

    test('describes each entry in company time', () {
      final retryAt = testNow.add(const Duration(seconds: 20));
      final model = SyncQueueSheetModel();

      expect(model.titleOf(_event('a')), 'Check-in · Wed 28 Oct, 09:02');
      expect(model.statusOf(_event('a')), AppStrings.eventWaiting);
      expect(
        model.statusOf(_event('a', nextAttemptAt: retryAt)),
        AppStrings.eventRetryAt('09:30'),
      );
      expect(
        model.statusOf(_event('a', status: SyncState.syncing)),
        AppStrings.eventSending,
      );
      expect(
        model.statusOf(_event('a', status: SyncState.synced)),
        AppStrings.eventSynced,
      );
      expect(
        model.statusOf(
          _event('a', status: SyncState.rejected, lastError: 'Already in.'),
        ),
        'Already in.',
      );
    });

    test('waiting entries: Sync now sends them, ignoring the backoff',
        () async {
      when(sync.queue).thenReturn([_event('a')]);
      when(sync.waitingCount).thenReturn(1);
      final model = SyncQueueSheetModel();

      expect(model.subtitle, AppStrings.syncSheetWaiting(1));
      expect(model.canSyncNow, isTrue);
      await model.syncNow();

      verify(sync.syncNow(ignoreBackoff: true)).called(1);
    });

    test('Sync now is disabled while a sync runs', () async {
      when(sync.queue).thenReturn([_event('a', status: SyncState.syncing)]);
      when(sync.waitingCount).thenReturn(1);
      when(sync.isSyncing).thenReturn(true);
      final model = SyncQueueSheetModel();

      expect(model.canSyncNow, isFalse);
      expect(model.syncButtonLabel, AppStrings.syncingNow);
      await model.syncNow();

      verifyNever(sync.syncNow(ignoreBackoff: anyNamed('ignoreBackoff')));
    });

    test('offline: explains when waiting entries will go', () {
      when(sync.queue).thenReturn([_event('a')]);
      when(sync.waitingCount).thenReturn(1);
      when(connectivity.isOnline).thenReturn(false);

      expect(SyncQueueSheetModel().subtitle, AppStrings.syncSheetOffline);
    });

    test('dismisses only rejected entries', () async {
      when(sync.dismiss(any)).thenAnswer((_) async {});
      final model = SyncQueueSheetModel();

      await model.dismiss(_event('a'));
      await model.dismiss(_event('b', status: SyncState.rejected));

      verify(sync.dismiss('b')).called(1);
      verifyNever(sync.dismiss('a'));
    });

    test('long-press toggles the event ID', () {
      final model = SyncQueueSheetModel();
      final event = _event('a');

      model.toggleReveal(event);
      expect(model.isRevealed(event), isTrue);
      model.toggleReveal(event);
      expect(model.isRevealed(event), isFalse);
    });
  });
}
