import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../constants.dart';
import '../../models/plan_meal.dart';
import '../../services/settings_service.dart';
import '../../widgets/main_button.dart';

class ChangeMealTypesModal extends ConsumerStatefulWidget {
  const ChangeMealTypesModal({Key? key}) : super(key: key);

  @override
  ConsumerState<ChangeMealTypesModal> createState() =>
      _ChangeMealTypeModalState();
}

class _ChangeMealTypeModalState extends ConsumerState<ChangeMealTypesModal> {
  final _log = Logger('ChangeMealTypesModal');

  late final AutoDisposeStateProvider<bool> _$breakfast;
  late final AutoDisposeStateProvider<bool> _$lunch;
  late final AutoDisposeStateProvider<bool> _$dinner;

  @override
  void initState() {
    final activeTypes = SettingsService.activeMealTypes;
    _$breakfast = AutoDisposeStateProvider(
        (_) => activeTypes.contains(MealType.BREAKFAST));
    _$lunch =
        AutoDisposeStateProvider((_) => activeTypes.contains(MealType.LUNCH));
    _$dinner =
        AutoDisposeStateProvider((_) => activeTypes.contains(MealType.DINNER));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'settings_section_customization_meal_types'
                        .tr()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: kPadding),
          _buildCheckboxTile(_$breakfast, 'breakfast'.tr()),
          _buildCheckboxTile(_$lunch, 'lunch'.tr()),
          _buildCheckboxTile(_$dinner, 'dinner'.tr()),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: 'save'.tr(),
              onTap: _save,
            ),
          ),
          const SizedBox(height: kPadding),
        ],
      ),
    );
  }

  Consumer _buildCheckboxTile(
    AutoDisposeStateProvider<bool> provider,
    String title,
  ) {
    return Consumer(builder: (context, ref, _) {
      return CheckboxListTile(
        value: ref.watch(provider),
        onChanged: (value) {
          ref.read(provider.notifier).state = value!;
        },
        title: Text(title.tr()),
      );
    });
  }

  Future<void> _save() async {
    var updatedTypes = [
      if (ref.read(_$breakfast)) MealType.BREAKFAST,
      if (ref.read(_$lunch)) MealType.LUNCH,
      if (ref.read(_$dinner)) MealType.DINNER,
    ];
    if (updatedTypes.isEmpty) {
      updatedTypes = [
        MealType.LUNCH,
        MealType.DINNER,
      ];
    }
    try {
      SettingsService.setActiveMealTypes(updatedTypes);
    } catch (e) {
      _log.severe('Failed to save meal types', e);
    }
    Navigator.pop(context);
  }
}
