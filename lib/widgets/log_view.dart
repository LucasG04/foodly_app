import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state_providers.dart';
import 'main_appbar.dart';

class LogView extends StatelessWidget {
  const LogView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(
        text: 'Logs',
      ),
      body: Consumer(
        builder: (_, ref, __) {
          final logs = context.read(logsProvider).state;
          return ListView.builder(
            itemBuilder: (_, index) => ListTile(
              title: Text(logs[index].loggerName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(logs[index].message),
                  Text(logs[index].level.name),
                ],
              ),
              isThreeLine: true,
              dense: true,
            ),
            itemCount: logs.length,
          );
        },
      ),
    );
  }
}
