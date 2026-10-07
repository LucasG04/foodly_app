import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/plan.dart';
import '../../services/foodly_user_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/sheet_header.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class SelectPlanModal extends StatefulWidget {
  final String userId;

  const SelectPlanModal(this.userId, {super.key});

  @override
  State<SelectPlanModal> createState() => _SelectPlanModalState();
}

class _SelectPlanModalState extends State<SelectPlanModal> {
  // Roughly two plan tiles, so the sheet keeps its height once plans load.
  static const _placeholderHeight = 150.0;

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
      padding: EdgeInsets.only(
        left: (size.width - width) / 2,
        right: (size.width - width) / 2,
        bottom: kPadding / 2 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: context.tr('modal_select_plan_title'),
          ),
          FutureBuilder<List<Plan>?>(
            future: _plansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: _placeholderHeight,
                  child: Center(child: SmallCircularProgressIndicator()),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: _placeholderHeight,
                  child: Center(
                    child: Text(
                      context.tr('modal_select_plan_no_plan'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.height * 0.6),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: snapshot.data!
                      .map(
                        (plan) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(plan.name!),
                          subtitle: Text(plan.code!),
                          onTap: () => Navigator.pop(context, plan),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
