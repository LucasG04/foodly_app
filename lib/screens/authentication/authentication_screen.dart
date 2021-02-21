import 'package:flutter/material.dart';
import 'code_input_view.dart';
import 'login_view.dart';

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  PageController _pageController;
  String planId;

  @override
  void initState() {
    _pageController = new PageController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
          child: PageView(
            controller: _pageController,
            children: [
              CodeInputView((enteredValue) {
                setState(() {
                  planId = enteredValue;
                });
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeIn,
                );
              }),
              LoginView(
                planId: planId,
                navigateBack: () {
                  setState(() {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeIn,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
