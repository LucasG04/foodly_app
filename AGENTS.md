# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

Foodly/Foodster: Flutter meal-planning app (weekly plan, cookbook, shopping list). Backend is the sibling repo `../lunix-api` (Bun/Express, see its `AGENTS.md`).

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # required after pub get / changing annotated code
flutter analyze --no-fatal-infos                           # CI lint gate
flutter test                                               # all tests
flutter test test/models/meal_test.dart                    # single file
flutter test --plain-name 'some test name'                 # single test
./pods-clean-update.sh                                     # clean + pod update after native dep changes
```

- Build runner generates `lib/app_router.gr.dart` (auto_route), `lib/utils/env.g.dart` (envied), `lib/objectbox.g.dart` (ObjectBox), `*.g.dart` Hive adapters. Never hand-edit these.
- `lib/utils/env.dart` reads `.env` at build time (obfuscated): `LUNIX_API_KEY`, `LUNIX_API_KEY_DEV`, `REVENUECAT_APPLE_KEY`, `REVENUECAT_GOOGLE_KEY`, `LUNIX_AUTH_USERNAME`, `LUNIX_AUTH_PASSWORD`, optional `FARO_COLLECTOR_URL`. Missing `.env` breaks codegen.
- CI pins Flutter `3.47.5` (Java 17 in CI; Gradle 9.3.1 also builds with Android Studio's Java 25).

## Architecture

- **Entry** `lib/main.dart`: Firebase init → Hive + static service `initialize()` calls → `ProviderScope` → `EasyLocalization` (`en`, `de`; strings in `assets/translations/*.json`). In widgets use `context.tr('key')` so text rebuilds on language change; static `'key'.tr()` only outside the widget tree (services) or in `initState`. Primary color is reactive via `SettingsService.primaryColorListenable` → `MaterialApp.theme`; read it from `Theme.of(context)`, never restart the app.
- **Services** (`lib/services/`): static-only classes with private constructors, no DI. Most wrap Firestore collections via `withConverter` (e.g. `PlanService` → `plans`), models expose `fromMap`/`toMap`.
- **State** (`lib/providers/`): Riverpod `StateProvider`s for global state (`planProvider`, `userProvider`, …); `FoodlyApp` streams user/plan from Firestore and writes them into providers.
- **Routing**: auto_route v5 in `lib/app_router.dart`; regenerate after edits.
- **Local storage**: Hive boxes (settings, plan, link metadata, versions); ObjectBox only for the image cache (`models/cached_image.dart`, `services/image_cache_manager.dart`). Hive can't move to `hive_ce` because of an envied issue (see `pubspec.yaml`).
- **lunix-api** (`services/lunix_api_service.dart`): Dio with `x-api-key` + Basic auth; user-scoped calls add `x-firebase-token`. `SettingsService.useDevApi` switches to `lunix-api-dev.golenia.dev`. AI features (meal generation, kcal estimates) go through here; quota/rate limits surface as `AiQuotaExceededException` / `RateLimitException`.
- **Observability**: Grafana Faro (`faro`) in release builds when `FARO_COLLECTOR_URL` is set (`main.dart` `_runApp`): RUM, Dart errors, `>= WARNING` logs, and `FaroHttpOverrides` traces dart:io/Dio requests with `traceparent` into lunix-api. Crashlytics stays (native crashes); Faro must start after Crashlytics sets `FlutterError.onError` (it chains it).
- **Premium**: RevenueCat (`in_app_purchase_service.dart`), synced to `users/{id}.isPremium`.

## Conventions

- Widget tests: give the pumped `MaterialApp` `localizationsDelegates: testLocalizationsDelegates` (`test/helpers/test_localizations.dart`), otherwise `context.tr` throws `LocalizationNotFoundException`.
- Strict lints in `analysis_options.yaml`: relative imports, single quotes, `prefer_final_locals`, `avoid_print`, etc.
- iOS: FlutterFire plugins resolve via Swift Package Manager (Flutter default). Don't re-add the precompiled `FirebaseFirestore` pod to `ios/Podfile` (duplicate symbols).
- Android: `android/build.gradle` forces `compileSdkVersion 36` on plugin subprojects because some plugins pin an old one that fails AGP's AAR metadata check.

## UI: picking values

No `DropdownButton`/`PopupMenuButton`. Pick by context; the current choice is always visible in the primary color (`theme.primaryColor`, user-selectable):

- **Actions** (e.g. camera vs. gallery): `OptionsSheet` of `OptionsSheetOptions` with icons (`lib/widgets/options_modal/`), shown via `WidgetUtils.showFoodlyBottomSheet`.
- **A setting's value** (language, sort, export type): `SettingsTile(value: currentLabel, onTap: …)` shows the value + chevron; the tap opens an `OptionsSheet` with `selected: true` on the current option (tint + checkmark). Only for short lists; each row is ~80 px, so ~5 options max.
- **Single or multi choice inside a form sheet**, free-length labels (grocery group, tags): wrapping `TagChip` cloud, `Wrap(spacing/runSpacing: kPadding / 2)`. No horizontal-scrolling chip rows.
- **Ordered, fixed-count values** (days, meal types): grid of equal two-line tiles (small label/icon over a bold value), 4 per row, or one row when there are ≤ 3 options. Sized by content (not fixed aspect ratio). Selected tile filled with primary color + white text, others the 6 % text-color fill of `OptionsSheetOptions`; wrap in `Semantics(selected: …)`. Several grids in one sheet each get a small section label (600 weight, 60 % text color) and `kPadding` between them. Reference: `_buildTileGrid` / `_buildTile` in `plan_move_meal_modal.dart`.

## Release

Push to `master` deploys (iOS → TestFlight, Android → Play internal via fastlane). Version comes from the **commit message**, which must start with the version, e.g. `1.2.3 - New Release` (`.github/scripts/update_version*.sh`). PRs target `master` and run analyze + test; `dev` is the integration branch.
