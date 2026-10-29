import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/ui/views/main/main_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('MainViewModel -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('starts on the Today tab', () {
      expect(MainViewModel().currentIndex, MainViewModel.todayTab);
    });

    test('selectTab switches tabs', () {
      final model = MainViewModel()..selectTab(MainViewModel.leaveTab);
      expect(model.currentIndex, MainViewModel.leaveTab);
    });
  });
}
