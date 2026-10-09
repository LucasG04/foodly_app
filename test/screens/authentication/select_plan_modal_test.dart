import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/plan.dart';
import 'package:foodly/screens/authentication/select_plan_modal.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';

import '../../helpers/test_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Future<List<Plan>?> Function() loadPlans,
  ) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(
        // New key per pump, so each call starts a fresh load.
        body: SelectPlanModal('user', loadPlans: loadPlans, key: UniqueKey()),
      ),
    ));
    await tester.pump();
  }

  testWidgets('shows a spinner while loading', (tester) async {
    final completer = Completer<List<Plan>?>();
    await pump(tester, () => completer.future);
    expect(find.byType(SmallCircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error instead of "no plans" when loading fails',
      (tester) async {
    await pump(tester, () => Future.error(StateError('offline')));
    expect(find.text('login_error_unknown'), findsOneWidget);
    expect(find.text('modal_select_plan_no_plan'), findsNothing);
  });

  testWidgets('explains when the user has no plans', (tester) async {
    for (final plans in [null, <Plan>[]]) {
      await pump(tester, () async => plans);
      expect(find.text('modal_select_plan_no_plan'), findsOneWidget,
          reason: '$plans');
    }
  });

  testWidgets('lists plans, including ones without name or code',
      (tester) async {
    await pump(
        tester,
        () async => [
              Plan(id: '1', name: 'Family', code: 'ABC'),
              Plan(id: '2'),
            ]);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('ABC'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a plan returns it', (tester) async {
    final plan = Plan(id: '1', name: 'Family', code: 'ABC');
    Plan? picked;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showModalBottomSheet<Plan>(
              context: context,
              builder: (_) =>
                  SelectPlanModal('user', loadPlans: () async => [plan]),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(picked, same(plan));
  });
}
