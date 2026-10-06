import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/grocery_group.dart';
import '../services/lunix_api_service.dart';

/// The app's language code, kept in sync with the UI locale by `FoodlyApp`.
final languageCodeProvider = StateProvider<String?>((_) => null);

/// Grocery groups, localized by the API; refetched when the language changes.
final dataGroceryGroupsProvider =
    FutureProvider<List<GroceryGroup>>((ref) async {
  final langCode = ref.watch(languageCodeProvider);
  if (langCode == null) {
    // Stay loading until FoodlyApp sets the language; this provider then rebuilds.
    return Completer<List<GroceryGroup>>().future;
  }
  final previous = ref.state.valueOrNull;
  final groups = await LunixApiService.getGroceryGroups(langCode);
  if (groups.isEmpty) {
    // getGroceryGroups returns [] on failure: retry later, keep the last good list.
    final retry = Timer(const Duration(seconds: 30), ref.invalidateSelf);
    ref.onDispose(retry.cancel);
    return previous ?? [];
  }
  return groups;
});

/// Provides the supported sites to import dishes from
final dataSupportedImportSitesProvider = StateProvider<List<String>>((_) => []);
