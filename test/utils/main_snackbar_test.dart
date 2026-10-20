import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/main_snackbar.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => SnackbarHost(child: child!),
        home: const Scaffold(body: Text('list')),
      ));

  testWidgets('shows above a bottom sheet and back closes the sheet',
      (tester) async {
    await pumpApp(tester);
    late BuildContext sheetContext;
    showModalBottomSheet<void>(
      context: navigatorKey.currentContext!,
      builder: (context) {
        sheetContext = context;
        return const SizedBox(height: 300, child: Text('sheet'));
      },
    );
    await tester.pumpAndSettle();

    MainSnackbar(message: 'Saved', infinite: true).show(sheetContext);
    await tester.pumpAndSettle();
    // On top of the sheet: a tap reaches the message and dismisses it.
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(find.text('sheet'), findsOneWidget);

    MainSnackbar(message: 'Again').show(sheetContext);
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(find.text('Again'), findsOneWidget);
  });

  testWidgets('stays while the page underneath changes', (tester) async {
    await pumpApp(tester);
    navigatorKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('detail')),
    ));
    await tester.pumpAndSettle();

    MainSnackbar(message: 'Tip').show(navigatorKey.currentContext!);
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
  });

  testWidgets('hides after its duration and completes', (tester) async {
    await pumpApp(tester);
    var done = false;
    MainSnackbar(message: 'Bye', duration: 2)
        .show(navigatorKey.currentContext!)
        .then((_) => done = true);
    await tester.pumpAndSettle();
    expect(find.text('Bye'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Bye'), findsNothing);
    expect(done, isTrue);
  });

  testWidgets('an action runs and closes the message', (tester) async {
    await pumpApp(tester);
    var tapped = 0;
    MainSnackbar(
      message: 'Quota used up',
      action: TextButton(onPressed: () => tapped++, child: const Text('Get')),
    ).show(navigatorKey.currentContext!);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
    expect(find.text('Quota used up'), findsNothing);
  });

  testWidgets('an action with a tooltip can be shown', (tester) async {
    await pumpApp(tester);
    MainSnackbar(
      message: 'Removed',
      action: IconButton(
        tooltip: 'Undo',
        onPressed: () {},
        icon: const Icon(Icons.undo),
      ),
    ).show(navigatorKey.currentContext!);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Undo'), findsOneWidget);
  });

  testWidgets('the page underneath stays tappable', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => SnackbarHost(child: child!),
      home: Scaffold(
        body: Center(
          child: TextButton(onPressed: () => tapped++, child: const Text('Tap')),
        ),
      ),
    ));
    MainSnackbar(message: 'Hello').show(navigatorKey.currentContext!);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap'));
    expect(tapped, 1);
  });
}
