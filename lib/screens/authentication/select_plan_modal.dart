import 'package:auto_size_text/auto_size_text.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:foodly/models/plan.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/services/plan_service.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';

import '../../constants.dart';

class SelectPlanModal extends ConsumerWidget {
  final String userId;

  SelectPlanModal([this.userId]);

  @override
  Widget build(BuildContext context, watch) {
    final user = watch(userProvider).state;
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
                    'PLAN WÄHLEN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  GestureDetector(
                    child: Icon(EvaIcons.closeOutline),
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          user != null
              ? FutureBuilder<List<Plan>>(
                  future: PlanService.getPlansByIds(user.oldPlans),
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
                            'Du warst noch nie in einem Plan. Bitte erstelle einen Neuen oder tritt einem bei.',
                            textAlign: TextAlign.center,
                          ),
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
                  })
              : SizedBox(
                  height: size.height * 0.3,
                  child: Center(child: SmallCircularProgressIndicator()),
                ),
        ],
      ),
    );
  }
}