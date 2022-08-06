import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../widgets/main_appbar.dart';

class PlanHistoryView extends StatelessWidget {
  final Function() navigateBack;
  final ScrollController _scrollController = ScrollController();

  PlanHistoryView({
    required this.navigateBack,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: 'plan_history_title'.tr(),
        scrollController: _scrollController,
        showBack: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(EvaIcons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            FutureBuilder<dynamic>(
              future: Future<dynamic>.delayed(const Duration(seconds: 3)),
              builder: (context, snapshot) {
                return const SizedBox();
              },
            ),
            TextButton(
              onPressed: () {},
              child: Text('plan_history_back'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
