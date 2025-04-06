import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyboard_service/keyboard_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../constants.dart';
import '../../models/foodly_feedback.dart';
import '../../providers/state_providers.dart';
import '../../services/feedback_service.dart';
import '../../services/in_app_purchase_service.dart';
import '../../utils/main_snackbar.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  ButtonState _buttonState = ButtonState.normal;
  String? _textError;
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    _textFocusNode.addListener(_scrollToBottomIfFocused);
    super.initState();
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width > 699
        ? 700.0
        : MediaQuery.of(context).size.width * 0.8;

    return KeyboardAutoDismiss(
      scaffold: Scaffold(
        appBar: MainAppBar(
          text: 'feedback_title'.tr(),
          scrollController: _scrollController,
        ),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Center(
                  child: SizedBox(
                    width: fullWidth,
                    child: Column(
                      // ignore: avoid_redundant_argument_values
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MainTextField(
                          controller: _titleController,
                          title: 'feedback_title_title'.tr(),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: kPadding / 2),
                        MainTextField(
                          controller: _emailController,
                          title: 'feedback_email_title'.tr(),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: kPadding / 2),
                        MainTextField(
                          controller: _textController,
                          title: 'feedback_text_title'.tr(),
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          isMultiline: true,
                          errorText: _textError?.tr(),
                          focusNode: _textFocusNode,
                          required: true,
                        ),
                        const SizedBox(height: kPadding),
                        MainButton(
                          text: 'feedback_cta'.tr(),
                          iconData: EvaIcons.paperPlaneOutline,
                          onTap: _sendFeedback,
                          isProgress: true,
                          buttonState: _buttonState,
                        ),
                        const SizedBox(height: kPadding * 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scrollToBottomIfFocused() async {
    if (_textFocusNode.hasFocus) {
      await Future<int?>.delayed(const Duration(milliseconds: 300));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> _sendFeedback() async {
    if (!isTextValid(_textController.text)) {
      setState(() {
        _buttonState = ButtonState.error;
        _textError = 'feedback_text_error';
      });
      return;
    }
    _textError = null;
    setState(() {
      _buttonState = ButtonState.inProgress;
    });

    final appInfo = await PackageInfo.fromPlatform();

    if (!mounted) {
      return;
    }

    final feedback = FoodlyFeedback(
      userId: ref.read(userProvider)!.id!,
      planId: ref.read(planProvider)!.id!,
      date: DateTime.now(),
      title: _titleController.text.trim(),
      email: _emailController.text.trim(),
      description: _textController.text.trim(),
      version: '${appInfo.version} (${Platform.operatingSystem})',
      isSubscribedToPremium: ref.read(InAppPurchaseService.$userIsSubscribed),
    );

    await FeedbackService.create(feedback);

    // display "thanks" and close
    if (!mounted) {
      return;
    }
    MainSnackbar(
      message: 'feedback_thanks'.tr(args: ['']),
      isSuccess: true,
      duration: 1,
    ).show(context);
    await Future<int?>.delayed(const Duration(seconds: 1));

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  bool isTextValid(String? text) {
    return text != null && text.trim().isNotEmpty;
  }
}
