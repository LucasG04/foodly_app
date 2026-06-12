import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../providers/data_provider.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

enum ImportType { link, text }

class ImportModal extends ConsumerStatefulWidget {
  final ImportType type;

  const ImportModal({required this.type, super.key});

  @override
  ConsumerState<ImportModal> createState() => _ImportModalState();
}

class _ImportModalState extends ConsumerState<ImportModal> with OfContextMixin {
  late TextEditingController _controller;
  String? _errorText;
  ButtonState? _buttonState;

  @override
  void initState() {
    _controller = TextEditingController();
    _errorText = null;
    _buttonState = ButtonState.normal;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
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
                ),
                if (widget.type == ImportType.link)
                  IconButton(
                    onPressed: _showInfo,
                    icon: const Icon(EvaIcons.infoOutline),
                    color: theme.primaryColor,
                  ),
              ],
            ),
          ),
          if (widget.type == ImportType.link)
            MainTextField(
              controller: _controller,
              title: 'import_modal_link_title'.tr(),
              placeholder:
                  'https://www.chefkoch.de/rezepte/2280941363879458/Brokkoli-Spaetzle-Pfanne.html',
              errorText: _errorText,
              onSubmit: _importMeal,
              pasteFromClipboard: true,
              pasteValidator: (text) => BasicUtils.isValidUri(text),
              submitOnPaste: true,
            )
          else
            MainTextField(
              controller: _controller,
              title: 'import_modal_text_title'.tr(),
              placeholder: 'import_modal_text_hint'.tr(),
              errorText: _errorText,
              isMultiline: true,
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: mediaViewInsets.bottom == 0
                ? kPadding * 2
                : mediaViewInsets.bottom > 60
                    ? mediaViewInsets.bottom - 60
                    : mediaViewInsets.bottom,
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
    if (widget.type == ImportType.link) {
      await _importFromLink();
    } else {
      await _importFromText();
    }
  }

  Future<void> _importFromLink() async {
    final String? link = BasicUtils.getUrlFromString(_controller.text.trim());

    if (link == null || link.isEmpty || !BasicUtils.isValidUri(link)) {
      setState(() {
        _buttonState = ButtonState.error;
        _errorText = 'import_modal_error_no_link'.tr();
      });
      return;
    }

    setState(() {
      _errorText = null;
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

  Future<void> _importFromText() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _buttonState = ButtonState.error;
        _errorText = 'import_modal_error_no_text'.tr();
      });
      return;
    }

    setState(() {
      _errorText = null;
      _buttonState = ButtonState.inProgress;
    });

    try {
      final langCode = context.locale.languageCode;
      final meal = await LunixApiService.getMealFromText(text, langCode);
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
