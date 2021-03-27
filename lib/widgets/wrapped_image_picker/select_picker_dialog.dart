import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/services/storage_service.dart';
import 'package:foodly/utils/main_snackbar.dart';
import 'package:foodly/widgets/full_screen_loader.dart';
import 'package:foodly/widgets/main_text_field.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class SelectPickerDialog extends StatefulWidget {
  @override
  _SelectPickerDialogState createState() => _SelectPickerDialogState();
}

class _SelectPickerDialogState extends State<SelectPickerDialog> {
  Logger _log;

  bool _isLoading;
  ImagePicker _imagePicker;
  bool _showUrlInput;
  TextEditingController _linkController;
  bool _showLinkError;

  @override
  void initState() {
    _log = new Logger('SelectPickerDialog');
    _isLoading = false;
    _imagePicker = ImagePicker();
    _showUrlInput = false;
    _linkController = new TextEditingController();
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
                child: Center(child: SmallCircularProgressIndicator()),
              )
            : !_showUrlInput
                ? Wrap(
                    alignment: WrapAlignment.center,
                    spacing: kPadding / 2,
                    children: [
                      _buildPickerTypeTile(
                        EvaIcons.cameraOutline,
                        'Kamera',
                        () => _uploadLocalImage(ImageSource.camera),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.imageOutline,
                        'Gallerie',
                        () => _uploadLocalImage(ImageSource.gallery),
                      ),
                      _buildPickerTypeTile(
                        EvaIcons.globe2Outline,
                        'Web',
                        () => setState(() => (_showUrlInput = true)),
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
                            icon: Icon(EvaIcons.arrowBackOutline),
                            onPressed: () => setState(
                              () => (_showUrlInput = false),
                            ),
                          ),
                          IconButton(
                            icon: Icon(EvaIcons.checkmarkOutline),
                            onPressed: _setWebImageUrl,
                          ),
                        ],
                      ),
                      SizedBox(height: kPadding / 2),
                      MainTextField(
                        controller: _linkController,
                        onSubmit: _setWebImageUrl,
                        placeholder: 'http://food.com/images/23342',
                      ),
                      SizedBox(height: kPadding / 2),
                      _showLinkError
                          ? Row(
                              children: [
                                Icon(
                                  EvaIcons.alertCircleOutline,
                                  color: Theme.of(context).errorColor,
                                ),
                                SizedBox(height: kPadding / 2),
                                Expanded(
                                  child: Text(
                                    'Der Link konnte nicht aufgerufen werden. Bitte überprüfe ihn oder verwende die "Gallerie"-Funktion.',
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(),
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [kSmallShadow],
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(iconData, color: Theme.of(context).primaryColor),
            Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _uploadLocalImage(ImageSource source) async {
    final image = await _imagePicker.getImage(source: source);
    final upload = await StorageService.uploadFile(image);

    try {
      setState(() {
        _isLoading = true;
      });
      final result = await upload;
      _isLoading = false;
      Navigator.pop(context, result.ref.name);
    } catch (e) {
      _log.severe('ERR: StorageService.uploadFile', image);
      MainSnackbar(
        message:
            'Das Bild konnte leider nicht gespeichert werden. Wähle ein anderes Bild oder versuche es später erneut.',
        isError: true,
      ).show(context);
    }
  }

  void _setWebImageUrl() {
    _showLinkError = false;

    final String url = _linkController.text.trim();
    if (Uri.tryParse(url).isAbsolute) {
      Navigator.pop(context, url);
    } else {
      setState(() {
        _showLinkError = true;
      });
    }
  }
}
