import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/foodly_user.dart';
import '../../models/plan.dart';
import '../../services/foodly_user_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/small_circular_progress_indicator.dart';

import '../../constants.dart';

class SelectPlanModal extends ConsumerWidget {
  final String userId;

  SelectPlanModal(this.userId);

  @override
  Widget build(BuildContext context, watch) {
    final size = MediaQuery.of(context).size;
    final width =
        size.width > 599 ? 580.0 : MediaQuery.of(context).size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AutoSizeText(
                    'modal_select_plan_title'.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  GestureDetector(
                    child: Icon(EvaIcons.close),
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<FoodlyUser>(
            future: FoodlyUserService.getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: size.height * 0.3,
                  child: Center(child: SmallCircularProgressIndicator()),
                );
              } else if (!snapshot.hasData) {
                return SizedBox(
                  height: size.height * 0.3,
                  child: Center(
                    child: Text(
                      'modal_select_plan_no_plan',
                      textAlign: TextAlign.center,
                    ).tr(),
                  ),
                );
              }
              return _buildPlanList(snapshot.data, size.height * 0.3);
            },
          ),
        ],
      ),
    );
  }

  _buildPlanList(FoodlyUser user, double emptySpaceHeight) {
    return FutureBuilder<List<Plan>>(
      future: PlanService.getPlansByIds(user.oldPlans),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: emptySpaceHeight,
            child: Center(child: SmallCircularProgressIndicator()),
          );
        } else if (!snapshot.hasData) {
          return SizedBox(
            height: emptySpaceHeight,
            child: Center(
              child: Text(
                'modal_select_plan_no_plan',
                textAlign: TextAlign.center,
              ).tr(),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data.length,
          itemBuilder: (ctx, index) => ListTile(
            title: Text(snapshot.data[index].name),
            subtitle: Text(snapshot.data[index].code),
            onTap: () => Navigator.pop(ctx, snapshot.data[index]),
            trailing: Icon(Icons.arrow_forward_ios_rounded),
          ),
        );
      },
    );
  }
}
