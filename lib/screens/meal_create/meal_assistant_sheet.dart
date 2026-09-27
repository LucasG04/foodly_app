import 'dart:async';
import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:keep_screen_on/keep_screen_on.dart';

import '../../constants.dart';
import '../../models/image_credit.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_generation_event.dart';
import '../../services/ai_generation_exception.dart';
import '../../services/ai_quota_exceeded_exception.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/ai_usage_period.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/disposable_widget.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/main_text_field.dart';

/// What the sheet pops with. [partial] marks a new meal whose stream broke off.
typedef MealAssistantResult = ({Meal meal, bool partial});

/// Creates a meal from a prompt or pasted recipe, or edits [currentMeal] by a
/// change request. Pops with a [MealAssistantResult] once the stream is done.
class MealAssistantSheet extends StatefulWidget {
  /// The live form state; null when the form is still empty (create).
  final Meal? currentMeal;

  const MealAssistantSheet({this.currentMeal, super.key});

  @override
  State<MealAssistantSheet> createState() => _MealAssistantSheetState();
}

class _MealAssistantSheetState extends State<MealAssistantSheet>
    with OfContextMixin, DisposableWidget {
  final _controller = TextEditingController();

  /// The submitted request; non-null while generating.
  String? _request;
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
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.8;
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
          _buildInput(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _request == null
                ? const SizedBox(width: double.infinity)
                : _buildStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'meal_assistant_title'.tr().toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(EvaIcons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final canSend = value.text.trim().isNotEmpty;
        return MainTextField(
          controller: _controller,
          placeholder: _isEdit
              ? 'meal_assistant_hint_edit'.tr()
              : 'meal_assistant_hint_create'.tr(),
          isMultiline: true,
          minLines: 1,
          autofocus: true,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          // Stays on screen with the request while the assistant works.
          readOnly: _request != null,
          // Slides away on send so the field takes the full width.
          suffix: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _request != null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: canSend ? () => _send(_controller.text) : null,
                    tooltip: 'meal_assistant_send'.tr(),
                    icon: Icon(
                      EvaIcons.paperPlaneOutline,
                      color: canSend ? theme.primaryColor : Colors.grey,
                    ),
                  ),
          ),
        );
      },
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
                      'meal_assistant_status_done'.tr(),
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
      return 'import_modal_enriching'.tr();
    }
    return _name == null
        ? 'meal_assistant_status_thinking'.tr()
        : 'meal_assistant_status_writing'.tr();
  }

  void _send(String text) {
    final request = text.trim();
    if (request.isEmpty || _request != null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _request = request);
    KeepScreenOn.turnOn();

    LunixApiService.streamGeneratedMeal(
      source: MealGenerationSource.text,
      data: request,
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
      Navigator.pop(context, (meal: _assembleMeal(), partial: true));
      return;
    }
    _showError(
      _hasContent
          ? 'meal_assistant_error_edit_incomplete'.tr()
          : _messageFor(code),
    );
    setState(_backToInput);
  }

  void _onSetupError(Object error, StackTrace _) {
    if (!mounted) {
      return;
    }
    if (error is AiQuotaExceededException) {
      MainSnackbar(
        message: 'ai_usage_exhausted'.plural(
          AiUsagePeriod.daysUntilReset(),
          namedArgs: {
            'date': DateFormat.Md(context.locale.toLanguageTag())
                .format(AiUsagePeriod.currentPeriodEnd().toLocal()),
          },
        ),
        isError: true,
        action: TextButton(
          onPressed: () => WidgetUtils.showFoodlyBottomSheet<void>(
            context: context,
            builder: (_) => const GetPremiumModal(),
          ),
          child: Text('ai_usage_upgrade'.tr()),
        ),
      ).show(context);
    } else {
      _showError(
        error is AIRejectionException
            ? _messageFor(error.code)
            : 'import_modal_error_generation'.tr(),
      );
    }
    setState(_backToInput);
  }

  /// The request stays in the field so the user can adjust and resend it.
  void _backToInput() {
    KeepScreenOn.turnOff();
    _request = null;
    _enriching = false;
    _name = null;
    _servings = null;
    _duration = null;
    _instructions = null;
    _ingredients.clear();
    _imageUrl = null;
    _imageCredit = null;
  }

  String _messageFor(MealGenerationErrorCode code) =>
      code == MealGenerationErrorCode.notFoodRelated
          ? 'meal_assistant_error_not_food'.tr()
          : 'import_modal_error_generation'.tr();

  void _showError(String message) {
    MainSnackbar(message: message, isError: true, isDismissible: true)
        .show(context);
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
      Navigator.pop(context, (meal: _assembleMeal(), partial: false));
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
