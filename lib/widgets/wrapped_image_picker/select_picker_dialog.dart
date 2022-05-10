import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

import '../../constants.dart';
import '../../services/storage_service.dart';
import '../../utils/main_snackbar.dart';
import '../main_text_field.dart';
import '../small_circular_progress_indicator.dart';

class SelectPickerDialog extends StatefulWidget {
  const SelectPickerDialog({Key? key}) : super(key: key);

  @override
  _SelectPickerDialogState createState() => _SelectPickerDialogState();
}

class _SelectPickerDialogState extends State<SelectPickerDialog> {
  late Logger _log;

  late bool _isLoading;
  late ImagePicker _imagePicker;
  late bool _showUrlInput;
  TextEditingController? _linkController;
  late bool _showLinkError;

  @override
  void initState() {
    _log = Logger('SelectPickerDialog');
    _isLoading = false;
    _imagePicker = ImagePicker();
    _showUrlInput = false;
    _linkController = TextEditingController();
    _showLinkError = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(kPadding),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? SizedBox(
                height: MediaQuery.of(context).size.width * 0.35,
                width: MediaQuery.of(context).size.width * 0.7,
                child: const Center(child: SmallCircularProgressIndicator()),
              )
            : !_showUrlInput
                ? Wrap(
                    alignment: WrapAlignment.center,
                    spacing: kPadding / 2,
                    children: [
                      _buildPickerTypeTile(
                        EvaIcons.cameraOutline,
                        'image_picker_dialog_camera'.tr(),
                        () => _uploadLocalImage(ImageSource.camera),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.imageOutline,
                        'image_picker_dialog_gallery'.tr(),
                        () => _uploadLocalImage(ImageSource.gallery),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.globe2Outline,
                        'image_picker_dialog_web'.tr(),
                        () => setState(() => _showUrlInput = true),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(EvaIcons.arrowBackOutline),
                            onPressed: () => setState(
                              () => _showUrlInput = false,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(EvaIcons.checkmark),
                            onPressed: _setWebImageUrl,
                          ),
                        ],
                      ),
                      const SizedBox(height: kPadding / 2),
                      MainTextField(
                        controller: _linkController,
                        onSubmit: _setWebImageUrl,
                        placeholder: 'http://food.com/images/23342',
                      ),
                      const SizedBox(height: kPadding / 2),
                      if (_showLinkError)
                        Row(
                          children: [
                            Icon(
                              EvaIcons.alertCircleOutline,
                              color: Theme.of(context).errorColor,
                            ),
                            const SizedBox(height: kPadding / 2),
                            Expanded(
                              child: const Text(
                                'image_picker_dialog_error_link',
                              ).tr(),
                            ),
                          ],
                        )
                      else
                        const SizedBox(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPickerTypeTile(
      IconData iconData, String text, Function() onTap) {
    return Container(
      height: 80.0,
      width: 80.0,
      margin: const EdgeInsets.all(kPadding / 2),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(iconData, color: Theme.of(context).primaryColor),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _uploadLocalImage(ImageSource source) async {
    try {
      final image = await _imagePicker.getImage(source: source);
      final upload = await StorageService.uploadFile(image);
      setState(() {
        _isLoading = true;
      });
      final result = await upload!;
      _isLoading = false;

      if (!mounted) {
        return;
      }
      Navigator.pop(context, result.ref.name);
    } catch (e) {
      _log.severe('ERR: StorageService.uploadFile', e);
      setState(() {
        _isLoading = false;
      });
      MainSnackbar(
        message: 'image_picker_dialog_error_not_found'.tr(),
        isError: true,
      ).show(context);
    }
  }

  void _setWebImageUrl() {
    _showLinkError = false;

    final String url = _linkController!.text.trim();
    if (Uri.tryParse(url)!.isAbsolute) {
      Navigator.pop(context, url);
    } else {
      setState(() {
        _showLinkError = true;
      });
    }
  }
}
