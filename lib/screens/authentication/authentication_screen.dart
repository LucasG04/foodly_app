import 'package:flutter/material.dart';

import '../../models/plan.dart';
import 'code_input_view.dart';
import 'login_view.dart';
import 'plan_settings_view.dart';

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  PageController _pageController;
  Plan _plan;
  bool _isCreatingPlan;

  @override
  void initState() {
    _pageController = new PageController();
    _isCreatingPlan = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            physics: NeverScrollableScrollPhysics(),
            children: [
              CodeInputView((result, [planId]) {
                setState(() {
                  _isCreatingPlan = result == CodeInputResult.NEW;
                  _plan = result == CodeInputResult.JOIN
                      ? new Plan(id: planId)
                      : null;
                });
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeIn,
                );
              }),
              _isCreatingPlan ? _buildPlanSettingsView() : _buildLoginView(),
              _isCreatingPlan ? _buildLoginView() : SizedBox()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSettingsView() {
    return PlanSettingsView(
      plan: _plan,
      navigateBack: () {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      },
      navigateForward: (plan) {
        setState(() {
          _plan = plan;
        });
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      },
    );
  }

  Widget _buildLoginView() {
    return LoginView(
      isCreatingPlan: _isCreatingPlan,
      plan: _plan,
      navigateBack: () {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeIn,
        );
      },
    );
  }
}
