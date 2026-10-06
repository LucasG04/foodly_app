// `Localization` isn't exported; context.tr looks it up by this exact type.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lets widgets under test call `context.tr` without loading translation
/// assets. Serves the same `Localization.instance` that static `.tr()` reads.
const testLocalizationsDelegates = [_InstanceLocalizationDelegate()];

class _InstanceLocalizationDelegate
    extends LocalizationsDelegate<Localization> {
  const _InstanceLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Localization> load(Locale locale) =>
      SynchronousFuture(Localization.instance);

  @override
  bool shouldReload(_InstanceLocalizationDelegate old) => false;
}
