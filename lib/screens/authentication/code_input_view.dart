import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import '../../services/plan_service.dart';
import '../../widgets/main_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';

import '../../constants.dart';
import 'login_design_clipper.dart';

class CodeInputView extends StatefulWidget {
  final void Function(String) onPageChange;

  CodeInputView(this.onPageChange);

  @override
  _CodeInputViewState createState() => _CodeInputViewState();
}

class _CodeInputViewState extends State<CodeInputView> {
  bool _loadingCode;
  TextEditingController _codeController;
  String _errorText;

  @override
  void initState() {
    _loadingCode = false;
    _codeController = new TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > 599 ? 600 : size.width * 0.9;
    return Container(
      child: Stack(
        children: <Widget>[
          ListView(
            padding: EdgeInsets.symmetric(
              horizontal:
                  (MediaQuery.of(context).size.width - contentWidth) / 2,
            ),
            children: [
              SizedBox(
                  height: size.height * 0.45 -
                      MediaQuery.of(context).viewInsets.bottom / 6),
              SizedBox(
                width: contentWidth * 0.7,
                child: Text(
                  'Gib den Code von einem Plan ein, um ihm beizutreten:',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: kPadding),
              _buildCodeInput(),
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     vertical: kPadding * 2,
              //     horizontal: kPadding,
              //   ),
              //   child: Center(child: Text('oder')),
              // ),
              SizedBox(height: size.height * 0.1),
              SizedBox(
                width: contentWidth * 0.7,
                child: Text(
                  'Hast du noch keinen Plan? Dann erstell einfach einen.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: kPadding * 2),
              Center(
                child: MainButton(
                  text: 'Plan erstellen',
                  onTap: () => widget.onPageChange(null),
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
                margin: EdgeInsets.only(left: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: size.height * 0.1),
                    Text(
                      'Wilkommen bei',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Foodly',
                      style: TextStyle(
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
      ),
    );
  }

  Widget _buildCodeInput() {
    return TextFormField(
      controller: _codeController,
      maxLines: 1,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.go,
      onChanged: _validateCode,
      style: TextStyle(
        fontSize: 42.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: '81726354',
        suffix: _loadingCode
            ? Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: SmallCircularProgressIndicator(),
              )
            : IconButton(
                icon: Icon(
                  EvaIcons.checkmark,
                  color: Theme.of(context).accentColor,
                ),
                onPressed: () => _validateCode(_codeController.text),
              ),
        errorText: _errorText,
      ),
    );
  }

  _validateCode(String text) async {
    _errorText = null;
    if (text.length == 8) {
      setState(() {
        _loadingCode = true;
      });

      // Check code
      try {
        final plan = await PlanService.getPlanByCode(text, withMeals: false);
        widget.onPageChange(plan.id);
      } catch (e) {
        print(e);
        setState(() {
          _errorText = 'Der Code ist leider nicht vergeben.';
        });
      }

      setState(() {
        _loadingCode = false;
      });
    }
  }
}
