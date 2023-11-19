import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../primary_colors.dart';
import '../../services/settings_service.dart';

class SettingsChangePrimaryColorModal extends ConsumerStatefulWidget {
  const SettingsChangePrimaryColorModal({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsChangePrimaryColorModal> createState() =>
      _SettingsChangePrimaryColorModalState();
}

class _SettingsChangePrimaryColorModalState
    extends ConsumerState<SettingsChangePrimaryColorModal> {
  late AutoDisposeStateProvider<Color> _$selected;

  @override
  void initState() {
    _$selected = AutoDisposeStateProvider(
      (_) => SettingsService.primaryColor,
    );
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
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AutoSizeText(
                    'settings_section_customization_change_color'
                        .tr()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  GestureDetector(
                    child: const Icon(EvaIcons.close),
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            runSpacing: kPadding / 2,
            spacing: kPadding / 2,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              // primaryDarkColor,
              primaryDarkGreenColor,
              primaryDarkBlueColor,
              primaryBlueColor,
              primaryRedColor,
              primaryOrangeColor,
              primaryPurpleColor,
              primaryPinkColor,
            ]
                .map(
                  (color) => Container(
                    height: kPadding * 3,
                    width: kPadding * 3,
                    decoration: BoxDecoration(
                      boxShadow: const [kSmallShadow],
                      color: color,
                      borderRadius: BorderRadius.circular(10000),
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        if (ref.watch(_$selected).value == color.value) {
                          return child!;
                        }
                        return GestureDetector(
                          onTap: () => _changeColor(color),
                          child: Container(color: Colors.transparent),
                        );
                      },
                      child: const Center(child: Icon(EvaIcons.checkmark)),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _changeColor(Color color) async {
    ref.read(_$selected.notifier).state = color;
    await SettingsService.setPrimaryColor(color);
    if (mounted) {
      Phoenix.rebirth(context);
    }
  }
}
