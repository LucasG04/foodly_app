import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/library_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/analytics.dart';
import '../../utils/main_snackbar.dart';

/// Copies library dishes into the current plan and refreshes the meal list.
/// Returns the plan's meals for [ids] and how many were copied now; null
/// (after an error snackbar) on failure. [entry] says where the import started (analytics).
///
/// Uses the ProviderScope container rather than the caller's `ref`: the
/// caller may be gone when the request returns, and the list must still
/// refresh.
Future<LibraryImport?> importFromLibrary(
  BuildContext context,
  List<String> ids, {
  required String entry,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final result = await LunixApiService.importLibraryMeals(
    container.read(planProvider)!.id!,
    ids,
    libraryLang(context.locale.languageCode),
  );
  if (result == null) {
    if (context.mounted) {
      MainSnackbar(
        message: context.tr('library_import_error'),
        isError: true,
      ).show(context);
    }
    return null;
  }
  if (result.created > 0) {
    container.read(libraryImportedProvider.notifier).state++;
  }
  logEvent(AnalyticsEvent.libraryImport, {
    'count': '${ids.length}',
    'entry': entry,
  });
  return result;
}
