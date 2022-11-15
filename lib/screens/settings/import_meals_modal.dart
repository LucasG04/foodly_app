import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../providers/state_providers.dart';
import '../../../services/meal_service.dart';
import '../../../services/plan_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../widgets/small_circular_progress_indicator.dart';

class ImportMealsModal extends StatelessWidget {
  final List<String?> planIds;

  const ImportMealsModal(this.planIds, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;

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
              child: const Text(
                'settings_import_title',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).tr(),
            ),
          ),
          FutureBuilder<List<Plan>>(
            future: PlanService.getPlansByIds(planIds),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) =>
                      CopyPlanMealsTile(snapshot.data![index]),
                );
              } else if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'settings_import_one_plan_msg',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.bodyText1!.fontSize! +
                                2,
                      ),
                    ).tr(),
                  ),
                );
              } else {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: SmallCircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
          SizedBox(
            height: kPadding * 2 + MediaQuery.of(context).viewInsets.bottom,
          ),
        ],
      ),
    );
  }
}

class CopyPlanMealsTile extends ConsumerStatefulWidget {
  final Plan plan;

  const CopyPlanMealsTile(this.plan, {Key? key}) : super(key: key);

  @override
  _CopyPlanMealsTileState createState() => _CopyPlanMealsTileState();
}

class _CopyPlanMealsTileState extends ConsumerState<CopyPlanMealsTile> {
  CopyButtonState _buttonState = CopyButtonState.normal;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(EvaIcons.minus),
      title: Text(widget.plan.name!),
      trailing: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buttonState == CopyButtonState.normal
              ? Icon(EvaIcons.copyOutline, key: UniqueKey())
              : _buttonState == CopyButtonState.loading
                  ? SmallCircularProgressIndicator(key: UniqueKey())
                  : Icon(
                      EvaIcons.checkmark,
                      key: UniqueKey(),
                      color: Colors.green,
                    ),
        ),
        onPressed: () => _copyMeals(
          ref.read(planProvider)!.id!,
        ),
      ),
    );
  }

  void _copyMeals(String currentPlanId) async {
    setState(() {
      _buttonState = CopyButtonState.loading;
    });

    final copiedMeals = await MealService.getAllMeals(widget.plan.id!);
    await MealService.addMeals(currentPlanId, copiedMeals);

    if (!mounted) {
      return;
    }
    BasicUtils.emitMealsChanged(ref);
    setState(() {
      _buttonState = CopyButtonState.done;
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      _buttonState = CopyButtonState.normal;
    });
  }
}

enum CopyButtonState { normal, loading, done }
