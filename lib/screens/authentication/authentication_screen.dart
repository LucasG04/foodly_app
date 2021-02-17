import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:foodly/widgets/main_button.dart';
import 'package:foodly/widgets/page_title.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';

import '../../constants.dart';
import 'login_design_clipper.dart';

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
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
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        child: GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: Container(
            child: Stack(
              children: <Widget>[
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
                ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        (MediaQuery.of(context).size.width - contentWidth) / 2,
                  ),
                  children: [
                    SizedBox(height: size.height * 0.45),
                    SizedBox(
                      width: contentWidth * 0.7,
                      child: Text(
                        'Gib den Code von einem Plan ein, um ihm beizutreten:',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: kPadding),
                    _buildCodeInput(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kPadding * 2,
                        horizontal: kPadding,
                      ),
                      // child: Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   mainAxisSize: MainAxisSize.max,
                      //   children: [
                      //     Container(
                      //       height: 1.0,
                      //       width: contentWidth * 0.3,
                      //       color: Colors.grey,
                      //     ),
                      //     Text('  oder  '),
                      //     Container(
                      //       height: 1.0,
                      //       width: contentWidth * 0.3,
                      //       color: Colors.grey,
                      //     ),
                      //   ],
                      // ),
                      child: Center(child: Text('oder')),
                    ),
                    SizedBox(
                      width: contentWidth * 0.7,
                      child: Text(
                        'Hast du noch keinen Plan? Dann erstell einfach einen.',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    //Butoon create plan
                    SizedBox(height: kPadding * 2),
                    Center(
                      child: MainButton(
                        text: 'Plan erstellen',
                        onTap: () => print('create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // return Scaffold(
    //   body: SafeArea(
    //     child: Padding(
    //       padding: EdgeInsets.symmetric(
    //         horizontal: (MediaQuery.of(context).size.width - contentWidth) / 2,
    //       ),
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           Spacer(),
    //           AutoSizeText(
    //             'Foodly',
    //             style: TextStyle(
    //               fontSize: 64.0,
    //               fontWeight: FontWeight.w700,
    //               fontFamily: 'Poppins',
    //             ),
    //           ),
    //           Spacer(),
    //           SizedBox(
    //             width: contentWidth * 0.7,
    //             child: Text(
    //               'Gib den Code von einem Plan ein, um ihm beizutreten:',
    //               style: TextStyle(fontSize: 18),
    //             ),
    //           ),
    //           SizedBox(height: kPadding),
    //           _buildCodeInput(),
    //           Padding(
    //             padding: const EdgeInsets.symmetric(
    //               vertical: kPadding * 2,
    //               horizontal: kPadding,
    //             ),
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 Divider(thickness: 1),
    //                 Text('  oder  '),
    //                 Divider(thickness: 1),
    //               ],
    //             ),
    //           ),
    //           SizedBox(
    //             width: contentWidth * 0.7,
    //             child: Text(
    //               'Hast du noch keinen Plan? Dann erstell einfach einen:',
    //               style: TextStyle(fontSize: 18),
    //             ),
    //           ),
    //           //Butoon create plan
    //           SizedBox(height: kPadding),
    //           Center(
    //             child: MainButton(
    //                 text: 'Plan erstellen', onTap: () => print('create')),
    //           ),
    //           SizedBox(height: size.height * 0.1),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget _buildCodeInput() {
    return TextFormField(
      controller: _codeController,
      maxLines: 1,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.go,
      onChanged: (text) async {
        if (text.length == 8) {
          setState(() {
            _loadingCode = true;
          });

          // Check code
          await Future.delayed(Duration(seconds: 2));

          setState(() {
            _loadingCode = false;
          });
        }
      },
      style: TextStyle(
        fontSize: 42.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: '81726354',
        suffix: _loadingCode ? SmallCircularProgressIndicator() : null,
        errorText: _errorText,
      ),
    );
  }
}
