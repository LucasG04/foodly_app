import 'dart:async';
import 'dart:collection';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_generation_event.dart';
import '../../providers/data_provider.dart';
import '../../services/ai_generation_exception.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/convert_util.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../widgets/disposable_widget.dart';
import '../../widgets/foodly_network_image.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';

enum ImportType { link, text, instagram }

/// Phases of the streaming import build-up. [scraping] only occurs for the
/// Instagram import, while the post/reel is being fetched.
enum _GenPhase { input, scraping, generating, enriching, done }

/// Sub-steps within [_GenPhase.enriching], each surfaced with its own status
/// copy. Derived from the enrichment events as they stream in. Ordered: the
/// step only ever advances forward (enrichment events may interleave / arrive
/// out of order, so a plain "latest event wins" would flicker the label).
enum _EnrichStep { polishing, sorting, image }

class ImportModal extends ConsumerStatefulWidget {
  final ImportType type;

  const ImportModal({required this.type, super.key});

  @override
  ConsumerState<ImportModal> createState() => _ImportModalState();
}

class _ImportModalState extends ConsumerState<ImportModal>
    with OfContextMixin, DisposableWidget {
  late TextEditingController _controller;
  String? _errorText;
  ButtonState? _buttonState;

  // Streaming build-up state (text import only).
  _GenPhase _phase = _GenPhase.input;
  // Current sub-step while [_phase] is [_GenPhase.enriching]. Only advances.
  _EnrichStep _enrichStep = _EnrichStep.polishing;
  // Set shortly after submit (once the fields have collapsed) so the button
  // morphs into the loader after the title/field leave, not at the same time.
  bool _buttonLoading = false;
  final ScrollController _scrollController = ScrollController();

  String? _name;
  int? _servings;
  int? _duration;
  String? _instructions;
  // Index-ordered so out-of-order enrichment events still render in order.
  final SplayTreeMap<int, Ingredient> _ingredients =
      SplayTreeMap<int, Ingredient>();
  String? _imageUrl;
  bool _imageResolved = false;
  bool _partialWarning = false;
  bool _popScheduled = false;

  // Context-independent markdown styling for streamed instructions; built once
  // rather than on every rebuild.
  static final MarkdownStyleSheet _instructionsStyleSheet =
      MarkdownStyleSheet.fromTheme(
    ThemeData(
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: kLightTextColor),
        bodyMedium: TextStyle(fontSize: 16, color: kLightTextColor),
      ),
    ),
  );

  @override
  void initState() {
    _controller = TextEditingController();
    _errorText = null;
    _buttonState = ButtonState.normal;
    super.initState();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// The text and Instagram imports both stream their result; the link import
  /// is a one-shot request with a static layout.
  bool get _isStreaming => widget.type != ImportType.link;

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
      ),
      child: !_isStreaming
          ? _buildInput()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _hasContent ? _buildGeneration() : _buildTextInputState(),
            ),
    );
  }

  Widget _buildTitleRow() {
    return Container(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.type == ImportType.link)
                IconButton(
                  onPressed: _showInfo,
                  icon: const Icon(EvaIcons.infoOutline),
                  color: theme.primaryColor,
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(EvaIcons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    switch (widget.type) {
      case ImportType.link:
        return MainTextField(
          controller: _controller,
          title: 'import_modal_link_title'.tr(),
          placeholder:
              'https://www.chefkoch.de/rezepte/2280941363879458/Brokkoli-Spaetzle-Pfanne.html',
          errorText: _errorText,
          onSubmit: _importMeal,
          pasteFromClipboard: true,
          pasteValidator: (text) => BasicUtils.isValidUri(text),
          submitOnPaste: true,
        );
      case ImportType.instagram:
        return MainTextField(
          controller: _controller,
          title: 'import_modal_instagram_title'.tr(),
          placeholder: 'instagram.com/reel/DVOxtiijAB-/',
          errorText: _errorText,
          onSubmit: _importMeal,
          pasteFromClipboard: true,
          pasteValidator: (text) => BasicUtils.isValidInstagramUrl(text),
          submitOnPaste: true,
        );
      case ImportType.text:
        return MainTextField(
          controller: _controller,
          title: 'import_modal_text_title'.tr(),
          placeholder: 'import_modal_text_hint'.tr(),
          errorText: _errorText,
          isMultiline: true,
        );
    }
  }

  Widget _buildKeyboardSpacer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      height: mediaViewInsets.bottom == 0
          ? kPadding * 2
          : mediaViewInsets.bottom > 60
              ? mediaViewInsets.bottom - 60
              : mediaViewInsets.bottom,
    );
  }

  /// Static input layout used for the link import (no streaming).
  Widget _buildInput() {
    return Column(
      key: const ValueKey('import-input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildTitleRow(),
        _buildTextField(),
        _buildKeyboardSpacer(),
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
    );
  }

  /// Text-import input that morphs into a loader: the title and field collapse
  /// and fade away first, then the submit button transitions into a centered
  /// spinner + status text occupying the button's footprint.
  Widget _buildTextInputState() {
    return Column(
      key: const ValueKey('import-input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _phase == _GenPhase.input
              ? Column(
                  key: const ValueKey('fields'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildTitleRow(),
                    _buildTextField(),
                    _buildKeyboardSpacer(),
                  ],
                )
              : const SizedBox(
                  key: ValueKey('fields-gone'),
                  width: double.infinity,
                  height: kPadding * 2,
                ),
        ),
        // Fixed height so the button and the loader share the same vertical
        // position — the button fully disappears, no layout shift.
        SizedBox(
          height: 60,
          child: Center(
            child: _buttonLoading
                ? _buildButtonLoader()
                : MainButton(
                    text: 'import_modal_import'.tr(),
                    onTap: _importMeal,
                    isProgress: true,
                    buttonState: _buttonState,
                  ),
          ),
        ),
        const SizedBox(height: kPadding * 2),
      ],
    );
  }

  /// The submit button morphed into a loading state: spinner + status text
  /// centered within the button's footprint (no button background).
  Widget _buildButtonLoader() {
    return SizedBox(
      key: const ValueKey('import-button-loader'),
      height: 60,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SmallCircularProgressIndicator(),
          const SizedBox(width: kPadding / 2),
          Flexible(
            child: Text(
              _loaderLabel(),
              style: const TextStyle(color: kLightTextColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Pre-content loader label: while an Instagram post is being scraped we say
  /// so explicitly; otherwise it's the generic "reading your recipe" copy.
  String _loaderLabel() => _phase == _GenPhase.scraping
      ? 'import_modal_scraping'.tr()
      : 'import_modal_generating'.tr();

  /// Status copy for the current enrichment sub-step.
  String _enrichLabel() {
    switch (_enrichStep) {
      case _EnrichStep.sorting:
        return 'import_modal_enriching_groups'.tr();
      case _EnrichStep.image:
        return 'import_modal_enriching_image'.tr();
      case _EnrichStep.polishing:
        return 'import_modal_enriching'.tr();
    }
  }

  /// Advances the enrichment sub-step forward only — enrichment events can
  /// interleave or arrive out of order, so the label must not jump backwards.
  void _advanceEnrichStep(_EnrichStep step) {
    if (step.index > _enrichStep.index) {
      _enrichStep = step;
    }
  }

  bool get _hasContent =>
      _name != null ||
      _ingredients.isNotEmpty ||
      (_instructions?.isNotEmpty ?? false) ||
      _imageResolved;

  Widget _buildGeneration() {
    return AnimatedSize(
      key: const ValueKey('import-generation'),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaSize.height * 0.9),
        child: _buildContentLayout(),
      ),
    );
  }

  Widget _buildContentLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Scrolling preview. Grows with the content until it reaches the
        // max height, then scrolls. Content fades out as it passes the top
        // edge so the latest text appears to flow up and out of the sheet.
        Flexible(
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: kLightTextColor),
            child: ShaderMask(
              shaderCallback: (bounds) {
                final fade = (28.0 / bounds.height).clamp(0.0, 0.5);
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const <Color>[
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                  ],
                  stops: <double>[0.0, fade, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  top: kPadding * 2,
                  bottom: kPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildHeader(),
                    _buildIngredients(),
                    _buildInstructions(),
                    _buildImage(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Pinned status indicator — never scrolls away.
        Padding(
          padding: EdgeInsets.only(
            top: kPadding / 2,
            bottom:
                mediaPadding.bottom > kPadding ? mediaPadding.bottom : kPadding,
          ),
          child: _buildFooter(),
        ),
      ],
    );
  }

  void _scrollToBottom() {
    BasicUtils.afterBuild(() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildImage() {
    final hasImage = _imageResolved && (_imageUrl?.isNotEmpty ?? false);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: !hasImage
          ? const SizedBox(key: ValueKey('no-image'), width: double.infinity)
          : Padding(
              key: const ValueKey('image'),
              padding: const EdgeInsets.only(top: kPadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FoodlyNetworkImage(_imageUrl!),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final Widget child;
    if (_name == null) {
      child = const SizedBox(key: ValueKey('header-loading'));
    } else {
      final meta = _buildMeta();
      child = Column(
        key: const ValueKey('header-meal'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_name!, style: kCardTitle),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: kPadding / 2),
            Wrap(
              spacing: kPadding,
              runSpacing: kPadding / 2,
              children: meta,
            ),
          ],
        ],
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }

  List<Widget> _buildMeta() {
    return <Widget>[
      if (_duration != null && _duration! > 0)
        _metaChip(EvaIcons.clockOutline, '$_duration min'),
      if (_servings != null && _servings! > 0)
        _metaChip(EvaIcons.peopleOutline, '$_servings'),
    ];
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: kLightTextColor),
        const SizedBox(width: kPadding / 4),
        Text(label, style: kCardSubtitle),
      ],
    );
  }

  Widget _buildIngredients() {
    if (_ingredients.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'meal_create_ingredients_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: kPadding / 2),
          _GenerationIngredientList(ingredients: _ingredients.values.toList()),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final instructions = _instructions;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: instructions == null || instructions.trim().isEmpty
          ? const SizedBox(key: ValueKey('no-instructions'))
          : Padding(
              key: const ValueKey('instructions'),
              padding: const EdgeInsets.only(top: kPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'meal_create_instruction_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: kPadding / 2),
                  MarkdownBody(
                    data: instructions,
                    styleSheet: _instructionsStyleSheet,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFooter() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildFooterChild(),
    );
  }

  Widget _buildFooterChild() {
    switch (_phase) {
      case _GenPhase.enriching:
        return _statusRow(
          ValueKey('enriching-${_enrichStep.name}'),
          _enrichLabel(),
        );
      case _GenPhase.done:
        return Row(
          key: const ValueKey('done'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _partialWarning
                  ? EvaIcons.alertCircleOutline
                  : EvaIcons.checkmarkCircle2Outline,
              color: _partialWarning ? kLightTextColor : Colors.green,
            ),
            const SizedBox(width: kPadding / 2),
            Flexible(
              child: Text(
                _partialWarning
                    ? 'import_modal_partial_warning'.tr()
                    : _name ?? '',
                style: const TextStyle(color: kLightTextColor),
              ),
            ),
          ],
        );
      case _GenPhase.scraping:
        return _statusRow(
          const ValueKey('scraping'),
          'import_modal_scraping'.tr(),
        );
      case _GenPhase.generating:
      case _GenPhase.input:
        return _statusRow(
          const ValueKey('generating'),
          'import_modal_generating'.tr(),
        );
    }
  }

  Widget _statusRow(Key key, String label) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SmallCircularProgressIndicator(),
        const SizedBox(width: kPadding / 2),
        Text(label, style: const TextStyle(color: kLightTextColor)),
      ],
    );
  }

  void _importMeal() async {
    if (widget.type == ImportType.link) {
      await _importFromLink();
    } else {
      _importStreaming();
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

  void _importStreaming() {
    if (_phase != _GenPhase.input) {
      return; // already submitting / streaming
    }
    final input = _controller.text.trim();

    final isInstagram = widget.type == ImportType.instagram;
    final isInvalid =
        isInstagram ? !BasicUtils.isValidInstagramUrl(input) : input.isEmpty;
    if (isInvalid) {
      setState(() {
        _buttonState = ButtonState.error;
        _errorText = isInstagram
            ? 'import_modal_error_no_instagram'.tr()
            : 'import_modal_error_no_text'.tr();
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorText = null;
      _phase = _GenPhase.generating; // collapses the title + field
      _enrichStep = _EnrichStep.polishing;
      _partialWarning = false;
    });

    // Once the fields have collapsed, morph the button into the loader.
    Future<void>.delayed(const Duration(milliseconds: 220)).then((_) {
      if (mounted && _phase != _GenPhase.input) {
        setState(() => _buttonLoading = true);
      }
    });

    final langCode = context.locale.languageCode;
    LunixApiService.streamGeneratedMeal(
      source: isInstagram
          ? MealGenerationSource.instagram
          : MealGenerationSource.text,
      data: input,
      langCode: langCode,
    )
        .listen(
          _onEvent,
          onError: _onStreamSetupError,
          cancelOnError: true,
        )
        .canceledBy(this);
  }

  void _onEvent(MealGenerationEvent event) {
    if (!mounted) {
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
          // Contract: ingredient events arrive in ascending index order. The
          // append-only [_GenerationIngredientList] relies on this; only
          // enrichment (product group / image) is allowed out of order.
          _ingredients[index] = ingredient;
        case PhaseEvent(value: 'scraping'):
          _phase = _GenPhase.scraping;
        case PhaseEvent(value: 'enriching'):
          _phase = _GenPhase.enriching;
        case PhaseEvent():
          break;
        case GroupEvent(:final index, :final group):
          _advanceEnrichStep(_EnrichStep.sorting);
          final existing = _ingredients[index];
          if (existing != null) {
            _ingredients[index] = existing.copyWith(group: group);
          }
        case ProductGroupEvent(:final index, :final productGroup):
          _advanceEnrichStep(_EnrichStep.sorting);
          final existing = _ingredients[index];
          if (existing != null) {
            _ingredients[index] = existing.copyWith(productGroup: productGroup);
          }
        case ImageEvent(:final imageUrl):
          _advanceEnrichStep(_EnrichStep.image);
          _imageUrl = imageUrl;
          _imageResolved = true;
        case DoneEvent():
          _phase = _GenPhase.done;
          _schedulePop();
        case ErrorEvent(:final code):
          if (_hasContent) {
            // Mid-stream error / premature close after partial content: keep
            // what we have, warn, and still hand it off.
            _partialWarning = true;
            _phase = _GenPhase.done;
            MainSnackbar(
              isError: true,
              message: 'import_modal_partial_warning'.tr(),
              isDismissible: true,
            ).show(context);
            _schedulePop();
          } else {
            // Error before any content arrived: treat like a setup failure and
            // return to the input so the user can retry.
            _phase = _GenPhase.input;
            _buttonLoading = false;
            _buttonState = ButtonState.error;
            MainSnackbar(
              isError: true,
              message: _messageForErrorCode(code),
              isDismissible: true,
            ).show(context);
          }
        case MealGenerationUnknownEvent():
          break;
      }
    });
    // Keep the newest content in view, just above the pinned footer.
    _scrollToBottom();
  }

  /// Pre-stream failures (no partial content): show a message and return to the
  /// input so the user can retry or edit.
  void _onStreamSetupError(Object error, StackTrace _) {
    if (!mounted) {
      return;
    }
    final message = error is AIRejectionException
        ? _messageForErrorCode(error.code)
        : 'import_modal_error_generation'.tr();
    MainSnackbar(
      isError: true,
      message: message,
      isDismissible: true,
    ).show(context);
    setState(() {
      _phase = _GenPhase.input;
      _buttonLoading = false;
      _buttonState = ButtonState.error;
    });
  }

  /// Friendly, code-specific copy for a terminal generation failure.
  String _messageForErrorCode(MealGenerationErrorCode code) {
    switch (code) {
      case MealGenerationErrorCode.notFoodRelated:
        return 'import_modal_error_not_food'.tr();
      case MealGenerationErrorCode.instagramFetchFailed:
        return 'import_modal_error_instagram_fetch'.tr();
      case MealGenerationErrorCode.internal:
      case MealGenerationErrorCode.streamInterrupted:
      case MealGenerationErrorCode.unknown:
        return 'import_modal_error_generation'.tr();
    }
  }

  /// Closes the modal shortly after completion so the finished build-up is
  /// visible, handing the assembled meal back to the caller.
  void _schedulePop() {
    if (_popScheduled) {
      return;
    }
    _popScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 700)).then((_) {
      if (!mounted) {
        return;
      }
      final hasUsableContent =
          (_name?.isNotEmpty ?? false) || _ingredients.isNotEmpty;
      Navigator.pop(context, hasUsableContent ? _assembleMeal() : null);
    });
  }

  Meal _assembleMeal() {
    final servings = (_servings ?? 1) < 1 ? 1 : (_servings ?? 1);
    return Meal(
      name: _name ?? '',
      servings: servings,
      duration: _duration,
      instructions: _instructions,
      ingredients: _ingredients.values.toList(),
      imageUrl: _imageUrl ?? '',
    );
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

/// Append-only animated list for the streaming ingredients. New ingredients
/// slide/fade in; in-place updates (e.g. a resolved product group) are
/// reflected without re-animating the row.
class _GenerationIngredientList extends StatefulWidget {
  final List<Ingredient> ingredients;

  const _GenerationIngredientList({required this.ingredients});

  @override
  State<_GenerationIngredientList> createState() =>
      _GenerationIngredientListState();
}

class _GenerationIngredientListState extends State<_GenerationIngredientList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Ingredient> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.ingredients);
  }

  @override
  void didUpdateWidget(covariant _GenerationIngredientList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newList = widget.ingredients;
    for (var i = 0; i < newList.length; i++) {
      if (i < _items.length) {
        // In-place update (e.g. resolved product group) — reflected on rebuild.
        _items[i] = newList[i];
      } else {
        _items.add(newList[i]);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 250),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) =>
          _buildTile(_items[index], animation),
    );
  }

  Widget _buildTile(Ingredient ingredient, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: curved,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.15, 0),
            end: Offset.zero,
          ).animate(curved),
          child: _IngredientRow(ingredient: ingredient),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final Ingredient ingredient;

  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final amount =
        ConvertUtil.amountToString(ingredient.amount, ingredient.unit);
    final hasGroup =
        ingredient.productGroup != null && ingredient.productGroup!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding / 4),
      child: Row(
        children: [
          const Icon(
            EvaIcons.arrowRightOutline,
            size: 16,
            color: kLightTextColor,
          ),
          const SizedBox(width: kPadding / 2),
          Expanded(
            child: Text(
              amount.isEmpty
                  ? (ingredient.name ?? '')
                  : '$amount ${ingredient.name ?? ''}',
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !hasGroup
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(ingredient.productGroup),
                    margin: const EdgeInsets.only(left: kPadding / 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: kPadding / 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kLightAccentColor,
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    child: Text(
                      ingredient.productGroup!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
