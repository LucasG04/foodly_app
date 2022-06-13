import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/plan_service.dart';
import '../../widgets/main_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'authentication_keys.dart';
import 'login_design_clipper.dart';

class CodeInputView extends StatefulWidget {
  final void Function(CodeInputResult, [String?]) onPageChange;

  const CodeInputView(
    this.onPageChange, {
    Key? key,
  }) : super(key: key);

  @override
  State<CodeInputView> createState() => _CodeInputViewState();
}

class _CodeInputViewState extends State<CodeInputView> {
  late bool _loadingCode;
  TextEditingController? _codeController;
  String? _errorText;

  @override
  void initState() {
    _loadingCode = false;
    _codeController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > 599 ? 600 : size.width * 0.9;
    return Stack(
      children: <Widget>[
        ListView(
          padding: EdgeInsets.symmetric(
            horizontal: (MediaQuery.of(context).size.width - contentWidth) / 2,
          ),
          children: [
            SizedBox(
                height: size.height * 0.41 -
                    MediaQuery.of(context).viewInsets.bottom / 6),
            SizedBox(
              width: contentWidth * 0.7,
              child: Text(
                '${'login_code_title_msg'.tr()}:',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: kPadding),
            _buildCodeInput(),
            SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: AuthenticationKeys.buttonForgotCode,
                  child: const Text('login_code_forgot').tr(),
                  onPressed: () => widget.onPageChange(CodeInputResult.FORGOT),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.1),
            SizedBox(
              width: contentWidth * 0.7,
              child: const Text(
                'login_code_no_plan',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ).tr(),
            ),
            const SizedBox(height: kPadding * 2),
            Center(
              child: MainButton(
                key: AuthenticationKeys.buttonCreatePlan,
                text: 'login_code_create_plan'.tr(),
                onTap: () => widget.onPageChange(CodeInputResult.NEW),
              ),
            ),
          ],
        ),
        ClipShadowPath(
          clipper: LoginDesignClipper(),
          shadow: Shadow(
            blurRadius: 24,
            color: Theme.of(context).primaryColor,
          ),
          child: Container(
            height: size.height * 0.4,
            width: size.width,
            color: Theme.of(context).primaryColor,
            child: Container(
              margin: const EdgeInsets.only(left: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: size.height * 0.1),
                  const Text(
                    'login_code_welcome',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                    ),
                  ).tr(),
                  Text(
                    kAppName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return TextFormField(
      key: AuthenticationKeys.inputCode,
      controller: _codeController,
      textInputAction: TextInputAction.go,
      onChanged: _validateCode,
      style: const TextStyle(
        fontSize: 42.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: '8Lu261gO',
        suffix: _loadingCode
            ? const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: SmallCircularProgressIndicator(),
              )
            : IconButton(
                icon: Icon(
                  EvaIcons.checkmark,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () => _validateCode(_codeController!.text),
              ),
        errorText: _errorText,
      ),
    );
  }

  void _validateCode(String text) async {
    _errorText = null;
    if (text.length == 8) {
      setState(() {
        _loadingCode = true;
      });

      // Check code
      try {
        final plan = await PlanService.getPlanByCode(text, withMeals: false);
        if (plan != null) {
          widget.onPageChange(CodeInputResult.JOIN, plan.id);
        } else {
          setState(() {
            _errorText = 'login_code_not_found'.tr();
          });
        }
      } catch (e) {
        setState(() {
          _errorText = 'login_code_not_found'.tr();
        });
      }

      setState(() {
        _loadingCode = false;
      });
    }
  }
}

// ignore: constant_identifier_names
enum CodeInputResult { JOIN, NEW, FORGOT }
