import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/foodly_user.dart';
import '../../models/plan.dart';
import '../../services/foodly_user_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class SelectPlanModal extends StatelessWidget {
  final String userId;

  const SelectPlanModal(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  GestureDetector(
                    child: const Icon(EvaIcons.close),
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<FoodlyUser?>(
            future: FoodlyUserService.getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: size.height * 0.3,
                  child: const Center(child: SmallCircularProgressIndicator()),
                );
              } else if (!snapshot.hasData) {
                return SizedBox(
                  height: size.height * 0.3,
                  child: Center(
                    child: const Text(
                      'modal_select_plan_no_plan',
                      textAlign: TextAlign.center,
                    ).tr(),
                  ),
                );
              }
              return _buildPlanList(snapshot.data!, size.height * 0.3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(FoodlyUser user, double emptySpaceHeight) {
    return FutureBuilder<List<Plan>>(
      future: PlanService.getPlansByIds(user.plans!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: emptySpaceHeight,
            child: const Center(child: SmallCircularProgressIndicator()),
          );
        } else if (!snapshot.hasData) {
          return SizedBox(
            height: emptySpaceHeight,
            child: Center(
              child: const Text(
                'modal_select_plan_no_plan',
                textAlign: TextAlign.center,
              ).tr(),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, index) => ListTile(
            title: Text(snapshot.data![index].name!),
            subtitle: Text(snapshot.data![index].code!),
            onTap: () => Navigator.pop(ctx, snapshot.data![index]),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        );
      },
    );
  }
}
