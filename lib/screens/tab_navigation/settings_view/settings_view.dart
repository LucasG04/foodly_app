import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/screens/tab_navigation/settings_view/import_meals_modal.dart';
import 'package:foodly/screens/tab_navigation/settings_view/settings_tile.dart';
import 'package:foodly/services/authentication_service.dart';
import 'package:foodly/services/plan_service.dart';
import 'package:foodly/widgets/page_title.dart';
import 'package:share/share.dart';

import '../../../constants.dart';

class SettingsView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, watch) {
    final plan = watch(planProvider).state;
    final foodlyUser = watch(userProvider).state;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: kPadding),
          PageTitle(text: 'Einstellungen'),
          _buildSectionTitle('Plan'),
          _buildSection([
            SettingsTile(
              onTap: () => _shareCode(plan.code),
              leadingIcon: EvaIcons.shareOutline,
              text: 'Plan teilen (${plan.code})',
              trailing: Icon(EvaIcons.arrowIosForwardOutline),
            ),
            SettingsTile(
              onTap: () => _leavePlan(plan.id),
              leadingIcon: EvaIcons.closeCircleOutline,
              text: 'Plan verlassen',
              trailing: Icon(
                EvaIcons.arrowIosForwardOutline,
                color: Colors.red,
              ),
              color: Colors.red,
            ),
          ], context),
          foodlyUser != null ? _buildSectionTitle('Gerichte') : SizedBox(),
          foodlyUser != null
              ? _buildSection([
                  SettingsTile(
                    onTap: () => _importMeals(
                      foodlyUser.oldPlans.where((id) => id != plan.id).toList(),
                      context,
                    ),
                    leadingIcon: EvaIcons.downloadOutline,
                    text: 'Alte Gerichte importieren',
                    trailing: Icon(EvaIcons.arrowIosForwardOutline),
                  ),
                ], context)
              : SizedBox(),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> widgets, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(bottom: kPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kPadding, 8, kPadding, 0),
        child: Wrap(children: widgets),
      ),
    );
  }

  Container _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kPadding,
          kPadding / 4,
          kPadding,
          kPadding / 2,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  void _shareCode(String code) {
    Share.share('Tritt meinem Essensplan bei Foodly mit dem Code "$code" bei.');
  }

  void _leavePlan(String planId) async {
    String userId = AuthenticationService.currentUser.uid;
    await PlanService.leavePlan(planId, userId);
    AuthenticationService.signOut();
  }

  void _importMeals(List<String> planIds, context) async {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) => ImportMealsModal(planIds),
    );
  }
}
