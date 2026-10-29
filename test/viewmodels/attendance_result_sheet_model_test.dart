import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/attendance_result.dart';
import 'package:rebs_hrms/ui/bottom_sheets/attendance_result/attendance_result_sheet_model.dart';
import 'package:stacked_services/stacked_services.dart';

import '../helpers/test_helpers.dart';

AttendanceResultSheetModel _model({bool isSynced = true}) =>
    AttendanceResultSheetModel(
      AttendanceResult(
        type: AttendanceEventType.checkIn,
        timeLabel: '09:02',
        placeLabel: 'Infopark Phase 1',
        isSynced: isSynced,
      ),
    );

void main() {
  group('AttendanceResultSheetModel -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('describes a synced check-in', () {
      final model = _model();

      expect(model.title, AppStrings.statusCheckedIn);
      expect(model.timeAndPlace, '09:02 · Infopark Phase 1');
      expect(model.syncLabel, AppStrings.resultSynced);
    });

    test('says it is saved on the phone when not synced', () {
      expect(_model(isSynced: false).syncLabel, AppStrings.resultSaved);
    });

    test('closes itself after 4 seconds, once', () {
      fakeAsync((async) {
        final responses = <SheetResponse>[];
        final model = _model()..startAutoClose(responses.add);

        async.elapse(const Duration(seconds: 3));
        expect(responses, isEmpty);
        async.elapse(const Duration(seconds: 1));
        expect(responses, hasLength(1));

        model.close(responses.add);
        expect(responses, hasLength(1));
      });
    });

    test('closing early cancels the timer', () {
      fakeAsync((async) {
        final responses = <SheetResponse>[];
        final model = _model()..startAutoClose(responses.add);

        model.close(responses.add);
        async.elapse(const Duration(seconds: 5));

        expect(responses, hasLength(1));
      });
    });
  });
}
