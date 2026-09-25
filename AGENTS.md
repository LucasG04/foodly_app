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
- `lib/utils/env.dart` reads `.env` at build time (obfuscated): `LUNIX_API_KEY`, `LUNIX_API_KEY_DEV`, `REVENUECAT_APPLE_KEY`, `REVENUECAT_GOOGLE_KEY`, `LUNIX_AUTH_USERNAME`, `LUNIX_AUTH_PASSWORD`. Missing `.env` breaks codegen.
- CI pins Flutter `3.47.5` (Java 17 in CI; Gradle 9.3.1 also builds with Android Studio's Java 25).

## Architecture

- **Entry** `lib/main.dart`: Firebase init → Hive + static service `initialize()` calls → `Phoenix` (app restart) → `ProviderScope` → `EasyLocalization` (`en`, `de`; strings in `assets/translations/*.json`, used as `'key'.tr()`).
- **Services** (`lib/services/`): static-only classes with private constructors, no DI. Most wrap Firestore collections via `withConverter` (e.g. `PlanService` → `plans`), models expose `fromMap`/`toMap`.
- **State** (`lib/providers/`): Riverpod `StateProvider`s for global state (`planProvider`, `userProvider`, …); `FoodlyApp` streams user/plan from Firestore and writes them into providers.
- **Routing**: auto_route v5 in `lib/app_router.dart`; regenerate after edits.
- **Local storage**: Hive boxes (settings, plan, link metadata, versions); ObjectBox only for the image cache (`models/cached_image.dart`, `services/image_cache_manager.dart`). Hive can't move to `hive_ce` because of an envied issue (see `pubspec.yaml`).
- **lunix-api** (`services/lunix_api_service.dart`): Dio with `x-api-key` + Basic auth; user-scoped calls add `x-firebase-token`. `SettingsService.useDevApi` switches to `lunix-api-dev.golenia.dev`. AI features (meal generation, kcal estimates) go through here; quota/rate limits surface as `AiQuotaExceededException` / `RateLimitException`.
- **Premium**: RevenueCat (`in_app_purchase_service.dart`), synced to `users/{id}.isPremium`.

## Conventions

- Strict lints in `analysis_options.yaml`: relative imports, single quotes, `prefer_final_locals`, `avoid_print`, etc.
- iOS: FlutterFire plugins resolve via Swift Package Manager (Flutter default). Don't re-add the precompiled `FirebaseFirestore` pod to `ios/Podfile` (duplicate symbols).
- Android: `android/build.gradle` forces `compileSdkVersion 36` on plugin subprojects because some plugins pin an old one that fails AGP's AAR metadata check.

## Release

Push to `master` deploys (iOS → TestFlight, Android → Play internal via fastlane). Version comes from the **commit message**, which must start with the version, e.g. `1.2.3 - New Release` (`.github/scripts/update_version*.sh`). PRs target `master` and run analyze + test; `dev` is the integration branch.
