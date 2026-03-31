import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/plan.dart';
import '../../services/foodly_user_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class SelectPlanModal extends StatefulWidget {
  final String userId;

  const SelectPlanModal(this.userId, {super.key});

  @override
  State<SelectPlanModal> createState() => _SelectPlanModalState();
}

class _SelectPlanModalState extends State<SelectPlanModal> {
  late final Future<List<Plan>?> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadUserPlans();
  }

  Future<List<Plan>?> _loadUserPlans() async {
    final user = await FoodlyUserService.getUserById(widget.userId);
    if (user?.plans == null || user!.plans!.isEmpty) {
      return null;
    }
    return PlanService.getPlansByIds(user.plans!);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width > 599 ? 580.0 : size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (size.width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
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
                ),
                IconButton(
                  icon: const Icon(EvaIcons.close),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Plan>?>(
            future: _plansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: size.height * 0.3,
                  child: const Center(child: SmallCircularProgressIndicator()),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: size.height * 0.3,
                  child: Center(
                    child: Text(
                      'modal_select_plan_no_plan'.tr(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!
                    .map(
                      (plan) => ListTile(
                        title: Text(plan.name!),
                        subtitle: Text(plan.code!),
                        onTap: () => Navigator.pop(context, plan),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
