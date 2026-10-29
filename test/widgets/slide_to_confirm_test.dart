// The one widget test allowed by TODO.md: drag behaviour can't be covered
// from a ViewModel.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/ui/widgets/common/slide_to_confirm.dart';

void main() {
  group('SlideToConfirm -', () {
    late int confirmations;
    late int lockedTaps;

    Future<void> pump(WidgetTester tester, {bool isLocked = false}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: SlideToConfirm(
                    label: 'Slide to check in',
                    isLocked: isLocked,
                    onLockedTap: () => lockedTaps++,
                    onConfirmed: () async {
                      confirmations++;
                      return true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

    Finder knob() => find.byIcon(Icons.arrow_forward_rounded);

    setUp(() {
      confirmations = 0;
      lockedTaps = 0;
    });

    testWidgets('a full drag fires once', (tester) async {
      await pump(tester);

      await tester.drag(knob(), const Offset(320, 0));
      await tester.pumpAndSettle();

      expect(confirmations, 1);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // After the tick it resets, ready for the next action.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(knob(), findsOneWidget);
      expect(confirmations, 1);
    });

    testWidgets('a short drag fires nothing and springs back', (tester) async {
      await pump(tester);

      await tester.drag(knob(), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(tester.getTopLeft(knob()).dx,
          lessThan(tester.getCenter(find.byType(SlideToConfirm)).dx));
    });

    testWidgets('a locked slider ignores drags and reports the attempt',
        (tester) async {
      await pump(tester, isLocked: true);

      await tester.drag(find.byIcon(Icons.lock_rounded), const Offset(320, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SlideToConfirm));
      await tester.pumpAndSettle();

      expect(confirmations, 0);
      expect(lockedTaps, 2);
    });
  });
}
