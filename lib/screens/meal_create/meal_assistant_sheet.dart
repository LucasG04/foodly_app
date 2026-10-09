import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:logging/logging.dart';

import '../../constants.dart';
import '../../models/image_credit.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_generation_event.dart';
import '../../services/ai_generation_exception.dart';
import '../../services/ai_quota_exceeded_exception.dart';
import '../../services/lunix_api_service.dart';
import '../../services/rate_limit_exception.dart';
import '../../utils/image_access.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/disposable_widget.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/options_modal/options_modal.dart';
import '../../widgets/options_modal/options_modal_option.dart';
import '../../widgets/sheet_header.dart';
import '../../widgets/small_circular_progress_indicator.dart';

/// Longest side the picker returns. With the 1024 px short side from
/// compression, the worst case (a tall 1024×2560 screenshot) stays around
/// 1 MB, under the API's 2 MB body limit.
const _kMaxImageSide = 2560.0;

/// The API cuts a photo's note to this many characters.
const _kMaxNoteLength = 1000;

/// What the sheet pops with. [partial] marks a new meal whose stream broke off;
/// [fromPhoto] a meal generated from a photo.
typedef MealAssistantResult = ({Meal meal, bool partial, bool fromPhoto});

/// Creates a meal from a prompt, pasted recipe or photo, or edits [currentMeal]
/// by a change request. Pops with a [MealAssistantResult] once the stream is done.
class MealAssistantSheet extends StatefulWidget {
  /// The live form state; null when the form is still empty (create).
  final Meal? currentMeal;

  const MealAssistantSheet({this.currentMeal, super.key});

  @override
  State<MealAssistantSheet> createState() => _MealAssistantSheetState();
}

class _MealAssistantSheetState extends State<MealAssistantSheet>
    with OfContextMixin, DisposableWidget {
  final _log = Logger('MealAssistantSheet');
  final _controller = TextEditingController();

  /// True while a request runs.
  bool _sending = false;

  /// The attached photo (compressed); sent with the next request.
  Uint8List? _image;

  /// True while a picked photo is compressed; sending waits for it.
  bool _compressing = false;
  bool _enriching = false;
  bool _done = false;

  String? _name;
  int? _servings;
  int? _duration;
  String? _instructions;
  final _ingredients = SplayTreeMap<int, Ingredient>();
  String? _imageUrl;
  ImageCredit? _imageCredit;

  bool get _isEdit => widget.currentMeal != null;

  bool get _hasContent =>
      (_name?.isNotEmpty ?? false) || _ingredients.isNotEmpty;

  @override
  void dispose() {
    KeepScreenOn.turnOff();
    cancelSubscriptions();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.9;
    // Above the keyboard when open, otherwise just clear the home indicator.
    final bottom = mediaViewInsets.bottom > 0
        ? mediaViewInsets.bottom + kPadding / 2
        : mediaPadding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: (mediaSize.width - width) / 2,
        right: (mediaSize.width - width) / 2,
        bottom: bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitleRow(),
          if (!_isEdit) _buildPhotoRow(),
          _buildInput(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_sending
                ? const SizedBox(width: double.infinity)
                : _buildStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return SheetHeader(
      title: context.tr('meal_assistant_title'),
    );
  }

  Widget _buildInput() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final text = value.text.trim();
        final noteTooLong = _image != null && text.length > _kMaxNoteLength;
        final canSend = !_compressing &&
            !noteTooLong &&
            (text.isNotEmpty || _image != null);
        final String placeholder;
        if (_isEdit) {
          placeholder = context.tr('meal_assistant_hint_edit');
        } else if (_image != null) {
          placeholder = context.tr('meal_assistant_hint_image');
        } else {
          placeholder = context.tr('meal_assistant_hint_create');
        }
        final field = MainTextField(
          controller: _controller,
          placeholder: placeholder,
          isMultiline: true,
          minLines: 1,
          autofocus: true,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          // Stays on screen with the request while the assistant works.
          readOnly: _sending,
          // Counter once a photo's note nears the limit.
          maxLength: _image != null && text.length > _kMaxNoteLength * 0.8
              ? _kMaxNoteLength
              : null,
          // Any tap outside (camera, send, preview) closes the keyboard. The
          // default unfocus also clears the focus history, so neither the
          // closing menu nor the returning photo picker refocuses the field.
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          // Slides away on send so the field takes the full width.
          suffix: _slideAwayOnSend(
            IconButton(
              onPressed: canSend ? _send : null,
              tooltip: context.tr('meal_assistant_send'),
              style: _edgeIconStyle(Alignment.centerRight),
              icon: Icon(
                EvaIcons.paperPlaneOutline,
                color: canSend ? theme.primaryColor : Colors.grey,
              ),
            ),
          ),
        );
        if (_isEdit) {
          return field; // the API reads photos for new meals only
        }
        return Row(
          children: [
            _slideAwayOnSend(_buildImageButton()),
            Expanded(child: field),
          ],
        );
      },
    );
  }

  /// [child], sliding away horizontally once a request is sent.
  Widget _slideAwayOnSend(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _sending ? const SizedBox.shrink() : child,
    );
  }

  /// Icon flush with the sheet edge ([alignment]), 12 px from the field; keeps
  /// a 36×48 tap target.
  static ButtonStyle _edgeIconStyle(Alignment alignment) =>
      IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 48),
        alignment: alignment,
      );

  /// The attached photo's preview (or a loader while compressing) above the
  /// field; empty without one.
  Widget _buildPhotoRow() {
    final Widget child;
    if (_compressing) {
      child = _buildCompressing();
    } else if (_image != null) {
      child = _buildPreview();
    } else {
      child = const SizedBox(width: double.infinity);
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  /// Stands in for the preview while a picked photo is compressed.
  Widget _buildCompressing() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: kPadding / 2),
      decoration: BoxDecoration(
        color: kGreyBackgroundColor,
        borderRadius: BorderRadius.circular(kRadius * 3),
      ),
      child: const Center(child: SmallCircularProgressIndicator()),
    );
  }

  /// Camera icon left of the field; picking a photo attaches (or replaces) it.
  Widget _buildImageButton() {
    return IconButton(
      tooltip: context.tr('meal_assistant_image'),
      style: _edgeIconStyle(Alignment.centerLeft),
      onPressed: _compressing ? null : _openImageSourceSheet,
      icon: Icon(EvaIcons.cameraOutline, color: theme.primaryColor),
    );
  }

  void _openImageSourceSheet() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => OptionsSheet(options: [
        OptionsSheetOptions(
          title: context.tr('meal_assistant_image_camera'),
          icon: EvaIcons.cameraOutline,
          onTap: () => _pickImage(ImageSource.camera),
        ),
        OptionsSheetOptions(
          title: context.tr('meal_assistant_image_gallery'),
          icon: EvaIcons.imageOutline,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ]),
    );
  }

  /// The attached photo in its own aspect ratio, like a chat app's attachment
  /// preview. The sheet grows to fit, up to 40 % of the height above the
  /// keyboard.
  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding / 2),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (mediaSize.height - mediaViewInsets.bottom) * 0.4,
          ),
          // Sized by the image; the button sits on its corner.
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(kRadius * 3),
                child: Image.memory(_image!),
              ),
              if (!_sending)
                Positioned(
                  top: kPadding / 2,
                  right: kPadding / 2,
                  child: IconButton.filled(
                    onPressed: () => setState(() => _image = null),
                    tooltip: context.tr('meal_assistant_image_remove'),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(EvaIcons.close),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: kPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _done
                ? const Icon(
                    EvaIcons.checkmarkCircle2Outline,
                    key: ValueKey('done'),
                    color: Colors.green,
                  )
                : Icon(
                    Icons.auto_awesome,
                    key: const ValueKey('working'),
                    color: theme.primaryColor,
                  ),
          ),
          const SizedBox(width: kPadding / 2),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _done
                  ? Text(
                      context.tr('meal_assistant_status_done'),
                      key: const ValueKey('status-done'),
                    )
                  : _Shimmer(
                      key: ValueKey(_statusLabel()),
                      color: theme.primaryColor,
                      child: Text(_statusLabel()),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    if (_enriching) {
      return context.tr('import_modal_enriching');
    }
    return _name == null
        ? context.tr('meal_assistant_status_thinking')
        : context.tr('meal_assistant_status_writing');
  }

  /// Sends the attached photo (the text is an optional note), else the text.
  void _send() {
    final text = _controller.text.trim();
    if (_sending || _compressing || (text.isEmpty && _image == null)) {
      return;
    }
    if (_image != null) {
      _start(
        MealGenerationSource.image,
        'data:image/jpeg;base64,${base64Encode(_image!)}',
        note: text.isEmpty ? null : text,
      );
    } else {
      _start(MealGenerationSource.text, text);
    }
  }

  /// Picks and compresses a photo the way [StorageService.uploadFile] does
  /// (from the file on native, from bytes on web), showing a loader in the
  /// preview slot meanwhile. A failed pick keeps the previous photo.
  Future<void> _pickImage(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: _kMaxImageSide,
        maxHeight: _kMaxImageSide,
      );
    } catch (e) {
      if (ImageAccess.isDenied(e)) {
        if (mounted) {
          await ImageAccess.request(context, source);
        }
        return;
      }
      _log.severe('pickImage failed', e);
      if (mounted) {
        _showError(context.tr('meal_assistant_error_image'));
      }
      return;
    }
    if (file == null || !mounted) {
      return; // cancelled
    }

    setState(() => _compressing = true);
    Uint8List? image;
    try {
      // Short side 1024 px, JPEG q80: a 4:3 photo becomes 1365×1024 (~0.15–0.5
      // MB), a long recipe screenshot stays readable.
      image = kIsWeb
          ? await FlutterImageCompress.compressWithList(
              await file.readAsBytes(),
              minWidth: 1024,
              minHeight: 1024,
              quality: 80,
            )
          : await FlutterImageCompress.compressWithFile(
              file.path,
              minWidth: 1024,
              minHeight: 1024,
              quality: 80,
            );
    } catch (e) {
      _log.severe('Compressing the image failed', e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _compressing = false;
      _image = image ?? _image;
    });
    if (image == null) {
      _showError(context.tr('meal_assistant_error_image'));
    }
  }

  void _start(MealGenerationSource source, String data, {String? note}) {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    KeepScreenOn.turnOn();

    LunixApiService.streamGeneratedMeal(
      source: source,
      data: data,
      note: note,
      langCode: context.locale.languageCode,
      currentMeal: widget.currentMeal,
    )
        .listen(_onEvent, onError: _onSetupError, cancelOnError: true)
        .canceledBy(this);
  }

  void _onEvent(MealGenerationEvent event) {
    if (!mounted) {
      return;
    }
    if (event is ErrorEvent) {
      _onStreamError(event.code);
      return;
    }
    setState(() {
      switch (event) {
        case MealFieldEvent(:final field, :final value):
          switch (field) {
            case 'name':
              _name = value as String?;
            case 'servings':
              _servings = num.tryParse(value.toString())?.round();
            case 'duration':
              _duration = num.tryParse(value.toString())?.round();
            case 'instructions':
              _instructions = value as String?;
          }
        case MealIngredientEvent(:final index, :final ingredient):
          _ingredients[index] = ingredient;
        case PhaseEvent(value: 'enriching'):
          _enriching = true;
        case GroupEvent(:final index, :final group)
            when _ingredients.containsKey(index):
          _ingredients.update(index, (i) => i.copyWith(group: group));
        case ProductGroupEvent(:final index, :final productGroup)
            when _ingredients.containsKey(index):
          _ingredients.update(
            index,
            (i) => i.copyWith(productGroup: productGroup),
          );
        case ImageEvent(:final imageUrl, :final imageCredit):
          _imageUrl = imageUrl;
          _imageCredit = imageCredit;
        case DoneEvent():
          _finish();
        case PhaseEvent():
        case GroupEvent():
        case ProductGroupEvent():
        case ErrorEvent():
        case MealGenerationUnknownEvent():
          break;
      }
    });
  }

  /// A broken-off new meal is still a useful start, so it is handed over. A
  /// broken-off edit is dropped: applying it would wipe the missing fields.
  void _onStreamError(MealGenerationErrorCode code) {
    if (_hasContent && !_isEdit) {
      KeepScreenOn.turnOff();
      Navigator.pop(
        context,
        (meal: _assembleMeal(), partial: true, fromPhoto: _image != null),
      );
      return;
    }
    _showError(
      _hasContent
          ? context.tr('meal_assistant_error_edit_incomplete')
          : _messageFor(code),
    );
    setState(_backToInput);
  }

  void _onSetupError(Object error, StackTrace _) {
    if (!mounted) {
      return;
    }
    if (error is AiQuotaExceededException) {
      GetPremiumModal.showAiQuotaExhausted(context, feature: 'assistant');
    } else if (error is RateLimitException) {
      _showError(error.message);
    } else {
      _showError(
        error is AIRejectionException
            ? _messageFor(error.code)
            : context.tr('import_modal_error_generation'),
      );
    }
    setState(_backToInput);
  }

  /// The request and photo stay so the user can adjust and resend them.
  void _backToInput() {
    KeepScreenOn.turnOff();
    _sending = false;
    _enriching = false;
    _name = null;
    _servings = null;
    _duration = null;
    _instructions = null;
    _ingredients.clear();
    _imageUrl = null;
    _imageCredit = null;
  }

  String _messageFor(MealGenerationErrorCode code) {
    if (code != MealGenerationErrorCode.notFoodRelated) {
      return context.tr('import_modal_error_generation');
    }
    return _image != null
        ? context.tr('meal_assistant_error_not_food_image')
        : context.tr('meal_assistant_error_not_food');
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    MainSnackbar(message: message, isError: true).show(context);
  }

  /// Shows the finished state briefly, then hands the meal to the form.
  void _finish() {
    if (_done) {
      return;
    }
    _done = true;
    KeepScreenOn.turnOff();
    Future<void>.delayed(const Duration(milliseconds: 600)).then((_) {
      if (!mounted) {
        return;
      }
      Navigator.pop(
        context,
        (meal: _assembleMeal(), partial: false, fromPhoto: _image != null),
      );
    });
  }

  Meal _assembleMeal() => Meal(
        name: _name ?? '',
        servings: (_servings ?? 1) < 1 ? 1 : _servings!,
        duration: _duration,
        instructions: _instructions,
        ingredients: _ingredients.values.toList(),
        imageUrl: _imageUrl ?? '',
        imageCredit: _imageCredit,
      );
}

/// Sweeps a highlight in [color] across [child] while the assistant works.
/// Static when the platform asks for reduced motion.
class _Shimmer extends StatefulWidget {
  final Color color;
  final Widget child;

  const _Shimmer({required this.color, required this.child, super.key});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = DefaultTextStyle.merge(
      style: const TextStyle(color: kLightTextColor),
      child: widget.child,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return text;
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Moves the band from off-left to off-right.
        final x = _animation.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x + 1, 0),
            colors: [kLightTextColor, widget.color, kLightTextColor],
          ).createShader(bounds),
          child: child,
        );
      },
      child: text,
    );
  }
}
