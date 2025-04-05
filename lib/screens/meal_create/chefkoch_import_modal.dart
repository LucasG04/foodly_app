import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../providers/data_provider.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

class ChefkochImportModal extends ConsumerStatefulWidget {
  const ChefkochImportModal({super.key});

  @override
  ConsumerState<ChefkochImportModal> createState() =>
      _ChefkochImportModalState();
}

class _ChefkochImportModalState extends ConsumerState<ChefkochImportModal> {
  TextEditingController _linkController = TextEditingController();
  String? _linkErrorText;

  ButtonState? _buttonState;

  @override
  void initState() {
    _linkController = TextEditingController();
    _linkErrorText = null;
    _buttonState = ButtonState.normal;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: kPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'import_modal_title'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  onPressed: _showInfo,
                  icon: const Icon(EvaIcons.infoOutline),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          MainTextField(
            controller: _linkController,
            title: 'import_modal_link_title'.tr(),
            placeholder:
                'https://www.chefkoch.de/rezepte/2280941363879458/Brokkoli-Spaetzle-Pfanne.html',
            errorText: _linkErrorText,
            onSubmit: _importMeal,
            pasteFromClipboard: true,
            pasteValidator: (text) => BasicUtils.isValidUri(text),
            submitOnPaste: true,
          ),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom == 0
                ? kPadding * 2
                : MediaQuery.of(context).viewInsets.bottom >
                        60 // 60 for MainButton
                    ? MediaQuery.of(context).viewInsets.bottom - 60
                    : MediaQuery.of(context).viewInsets.bottom,
          ),
          Center(
            child: MainButton(
              text: 'import_modal_import'.tr(),
              onTap: _importMeal,
              isProgress: true,
              buttonState: _buttonState,
            ),
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _importMeal() async {
    final String? link =
        BasicUtils.getUrlFromString(_linkController.text.trim());

    if (link == null || link.isEmpty || !BasicUtils.isValidUri(link)) {
      setState(() {
        _buttonState = ButtonState.error;
        _linkErrorText = 'import_modal_error_no_link'.tr();
      });
      return;
    }

    setState(() {
      _linkErrorText = null;
      _buttonState = ButtonState.inProgress;
    });

    try {
      final langCode = context.locale.languageCode;
      final meal = await LunixApiService.getMealFromUrl(link, langCode);
      if (meal == null) {
        _handleDownloadError();
        return;
      }
      _buttonState = ButtonState.normal;
      if (!mounted) {
        return;
      }
      FocusScope.of(context).unfocus();
      Navigator.pop(context, meal);
    } catch (e) {
      _handleDownloadError();
    }
  }

  void _showInfo() {
    final providerSites = ref.read(dataSupportedImportSitesProvider);
    final backupSites = ['chefkoch.de', 'kitchenstories.com'];
    var supportedSites = providerSites.isEmpty ? backupSites : providerSites;
    supportedSites = supportedSites.map((e) => '- $e').toList();
    var supportedSitesString = supportedSites.join('\n');
    supportedSitesString = '\n$supportedSitesString';

    MainSnackbar(
      message: 'import_modal_info'.tr(args: [supportedSitesString]),
      isDismissible: true,
      duration: 10,
    ).show(context);
  }

  void _handleDownloadError() {
    MainSnackbar(
      isError: true,
      title: 'import_modal_error_not_found_title'.tr(),
      message: 'import_modal_error_not_found'.tr(),
      isDismissible: true,
    ).show(context);
    setState(() {
      _buttonState = ButtonState.error;
    });
  }
}
