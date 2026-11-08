import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/mcp_connection.dart';
import 'package:foodly/screens/settings/mcp/mcp_api.dart';
import 'package:foodly/screens/settings/mcp/mcp_settings_modal.dart';
import 'package:foodly/utils/main_snackbar.dart';
// Transitive via easy_localization; only needed to mock its saved locale.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Reads translations from disk; the sheet reads `context.locale`, so it
/// needs a real [EasyLocalization] ancestor.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) =>
      Future.value(jsonDecode(
        File('$path/${locale.languageCode}.json').readAsStringSync(),
      ) as Map<String, dynamic>);
}

const _serverUrl = 'https://lunix-api.golenia.dev/foodly/mcp';

class _FakeApi extends McpApi {
  List<McpConnection> list;
  DateTime? keyCreatedAt;
  bool fail = false;
  final removed = <String>[];

  /// While set, connections() answers only once it completes, with the list
  /// as it was when called (a slow, now stale response).
  Completer<void>? gate;

  _FakeApi({this.list = const [], this.keyCreatedAt});

  @override
  String get serverUrl => _serverUrl;

  @override
  Future<List<McpConnection>> connections() async {
    if (fail) {
      throw Exception('offline');
    }
    final snapshot = [...list];
    await gate?.future;
    return snapshot;
  }

  @override
  Future<DateTime?> apiKeyCreatedAt() async => keyCreatedAt;

  @override
  Future<void> disconnect(String id) async {
    removed.add(id);
    list = list.where((c) => c.id != id).toList();
  }
}

McpConnection _connection(String id, String name) {
  final now = DateTime.now();
  return McpConnection(
      id: id, clientName: name, createdAt: now, lastUsedAt: now);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump(WidgetTester tester, McpApi api) async {
    tester.view.physicalSize = const Size(402, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The waiting dot pulses forever; reduced motion stops it for pumpAndSettle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('de')],
      path: 'assets/translations',
      assetLoader: const _FileAssetLoader(),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          builder: (_, child) => SnackbarHost(child: child!),
          home: Scaffold(
            body: SingleChildScrollView(child: McpSettingsModal(api: api)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('first visit: steps lead, then the waiting card', (tester) async {
    await pump(tester, _FakeApi());
    expect(find.text('So verbindest du deine KI-App'), findsOneWidget);
    expect(find.text('Noch keine App verbunden'), findsOneWidget);
    expect(find.text('Das kann deine KI'), findsNothing);
    expect(find.text(_serverUrl), findsOneWidget);
    expect(
      top(tester, 'So verbindest du deine KI-App'),
      lessThan(top(tester, 'Verbundene Apps')),
    );
    expect(find.text('Aktiv'), findsNothing);
  });

  testWidgets('with connections: the list leads, steps follow', (tester) async {
    await pump(
      tester,
      _FakeApi(
          list: [_connection('g1', 'Claude')], keyCreatedAt: DateTime(2026)),
    );
    expect(find.text('Claude'), findsOneWidget);
    expect(find.textContaining('Zuletzt aktiv: heute'), findsOneWidget);
    expect(find.text('Weitere App verbinden'), findsOneWidget);
    expect(
      top(tester, 'Verbundene Apps'),
      lessThan(top(tester, 'Weitere App verbinden')),
    );
    expect(find.text('Aktiv'), findsOneWidget);
  });

  testWidgets('returning to the app reveals and highlights a new connection',
      (tester) async {
    final api = _FakeApi();
    await pump(tester, api);
    api.list = [_connection('g1', 'Claude')];
    await resume(tester);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('Neu'), findsOneWidget);
    expect(find.text('Claude ist jetzt mit Foodly verbunden.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Neu'), findsNothing);
  });

  testWidgets('an unchanged list on resume celebrates nothing', (tester) async {
    await pump(tester, _FakeApi(list: [_connection('g1', 'Claude')]));
    await resume(tester);
    expect(find.text('Neu'), findsNothing);
  });

  testWidgets('disconnect asks first, then removes the app', (tester) async {
    final api = _FakeApi(list: [_connection('g1', 'Claude')]);
    await pump(tester, api);

    await tester.tap(find.text('Trennen'));
    await tester.pumpAndSettle();
    expect(find.text('Claude trennen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(api.removed, isEmpty);

    await tester.tap(find.text('Trennen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trennen').last);
    await tester.pumpAndSettle();
    expect(api.removed, ['g1']);
    expect(find.text('Claude'), findsNothing);
    expect(find.text('Noch keine App verbunden'), findsOneWidget);
  });

  testWidgets('copying the URL confirms inline', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await pump(tester, _FakeApi());
    await tester.tap(find.text(_serverUrl));
    await tester.pump();
    expect(copied, _serverUrl);
    expect(find.text('Kopiert'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Kopiert'), findsNothing);
  });

  testWidgets('load failure offers a retry', (tester) async {
    final api = _FakeApi()..fail = true;
    await pump(tester, api);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine App verbunden'), findsOneWidget);
  });

  testWidgets('resume after a failed load shows the list without celebrating',
      (tester) async {
    final api = _FakeApi()..fail = true;
    await pump(tester, api);
    api
      ..fail = false
      ..list = [_connection('g1', 'Claude')];
    await resume(tester);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsNothing);
    expect(find.text('Neu'), findsNothing);
    expect(find.text('Claude ist jetzt mit Foodly verbunden.'), findsNothing);
  });

  testWidgets('a reload started before a disconnect does not bring it back',
      (tester) async {
    final api = _FakeApi(list: [_connection('g1', 'Claude')]);
    await pump(tester, api);
    api.gate = Completer();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await tester.tap(find.text('Trennen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trennen').last);
    await tester.pumpAndSettle();
    expect(find.text('Claude'), findsNothing);

    api.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Claude'), findsNothing);
  });
}
